require "rails_helper"

RSpec.describe AcademicYear, type: :model do
  let!(:academic_year) { create(:academic_year) }

  describe "associations" do
    it { is_expected.to have_many(:partnership_academic_years) }
    it { is_expected.to have_many(:partnerships).through(:partnership_academic_years) }

    it { is_expected.to have_many(:provider_academic_years) }

    it { is_expected.to have_many(:providers).through(:provider_academic_years) }
  end

  describe "#current?" do
    context "when it is the current academic_year" do
      it "is expected to be true" do
        Timecop.travel(AcademicYearCalculator.current_academic_year, 9, 1) do
          expect(academic_year.current?).to be true
        end
      end
    end

    context "when it is not the current academic_year" do
      it "is expected to be false" do
        Timecop.travel(AcademicYearCalculator.previous_academic_year, 9, 1) do
          expect(academic_year.current?).to be false
        end
      end
    end
  end

  describe "#next?" do
    context "when it is the previous academic_year" do
      it "is expected to be true" do
        Timecop.travel(AcademicYearCalculator.previous_academic_year, 9, 1) do
          expect(academic_year.next?).to be true
        end
      end
    end

    context "when it is not the previous academic_year" do
      it "is expected to be false" do
        Timecop.travel(AcademicYearCalculator.current_academic_year, 9, 1) do
          expect(academic_year.next?).to be false
        end
      end
    end
  end

  describe "#last?" do
    context "when it is the next academic_year" do
      it "is expected to be true" do
        Timecop.travel(AcademicYearCalculator.next_academic_year, 9, 1) do
          expect(academic_year.last?).to be true
        end
      end
    end

    context "when it is not the current academic_year" do
      it "is expected to be false" do
        Timecop.travel(AcademicYearCalculator.current_academic_year, 9, 1) do
          expect(academic_year.last?).to be false
        end
      end
    end
  end

  describe ".for_year" do
    context "when an academic cycle exists for the given year" do
      it "returns the matching academic cycle" do
        academic_year
        expect(described_class.for_year(AcademicYearCalculator.current_academic_year)).to eq(academic_year)
      end
    end

    context "when no academic cycle exists for the given year" do
      it "returns nil" do
        expect(described_class.for_year(2023)).to be_nil
      end
    end
  end

  describe "#start_year and #end_year" do
    it "returns the correct start and end years" do
      ay = create(:academic_year, academic_year: 2025)

      expect(ay.start_year).to eq(2025)
      expect(ay.end_year).to eq(2026)
    end
  end

  describe ".start_date_for" do
    it "returns August 1 of the given year" do
      expect(described_class.start_date_for(2025))
        .to eq(Date.new(2025, 8, 1))
    end
  end

  describe ".covering_dates" do
    let!(:current_year) { create(:academic_year, :current) }
    let!(:previous_year) { create(:academic_year, :previous) }

    it "returns academic years covering a given date" do
      result = described_class.covering_dates(current_year.duration.begin,)

      expect(result).to contain_exactly(current_year)
    end

    it "returns multiple academic years when multiple dates match" do
      dates = [
        current_year.duration.begin,
        previous_year.duration.begin,
      ]

      result = described_class.covering_dates(dates)

      expect(result).to contain_exactly(current_year, previous_year)
    end

    it "returns none when given empty input" do
      expect(described_class.covering_dates([])).to be_empty
    end
  end

  describe ".for_specific_years" do
    let!(:current_year) { create(:academic_year, :current) }
    let!(:previous_year) { create(:academic_year, :previous) }
    let!(:next_year) { create(:academic_year, :next) }

    it "returns matching academic years for given years" do
      result = described_class.for_specific_years([previous_year.start_year, next_year.start_year])

      expect(result).to contain_exactly(previous_year, next_year)
    end

    it "orders results by duration descending" do
      result = described_class.for_specific_years([previous_year.start_year, current_year.start_year, next_year.start_year])

      expect(result).to eq([next_year, current_year, previous_year])
    end

    it "returns empty when no matches" do
      expect(described_class.for_specific_years([AcademicYearCalculator.previous_academic_year - 1])).to be_empty
    end

    it "handles single year input" do
      result = described_class.for_specific_years(current_year.start_year)

      expect(result).to contain_exactly(current_year)
    end
  end
end
