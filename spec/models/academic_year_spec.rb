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

  describe "#last??" do
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
end
