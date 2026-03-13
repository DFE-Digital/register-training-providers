require "rails_helper"

RSpec.describe AcademicCycle, type: :model do
  let!(:academic_cycle) { create(:academic_cycle) }

  describe "associations" do
    it { is_expected.to have_many(:partnership_academic_cycles) }
    it { is_expected.to have_many(:partnerships).through(:partnership_academic_cycles) }

    it { is_expected.to have_many(:provider_academic_cycles) }

    it { is_expected.to have_many(:providers).through(:provider_academic_cycles) }
  end

  describe "#current?" do
    context "when it is the current academic_cycle" do
      it "is expected to be true" do
        Timecop.travel(AcademicYearHelper.current_academic_year, 9, 1) do
          expect(academic_cycle.current?).to be true
        end
      end
    end

    context "when it is not the current academic_cycle" do
      it "is expected to be false" do
        Timecop.travel(AcademicYearHelper.previous_academic_year, 9, 1) do
          expect(academic_cycle.current?).to be false
        end
      end
    end
  end

  describe "#next?" do
    context "when it is the previous academic_cycle" do
      it "is expected to be true" do
        Timecop.travel(AcademicYearHelper.previous_academic_year, 9, 1) do
          expect(academic_cycle.next?).to be true
        end
      end
    end

    context "when it is not the previous academic_cycle" do
      it "is expected to be false" do
        Timecop.travel(AcademicYearHelper.current_academic_year, 9, 1) do
          expect(academic_cycle.next?).to be false
        end
      end
    end
  end

  describe "#last??" do
    context "when it is the next academic_cycle" do
      it "is expected to be true" do
        Timecop.travel(AcademicYearHelper.next_academic_year, 9, 1) do
          expect(academic_cycle.last?).to be true
        end
      end
    end

    context "when it is not the current academic_cycle" do
      it "is expected to be false" do
        Timecop.travel(AcademicYearHelper.current_academic_year, 9, 1) do
          expect(academic_cycle.last?).to be false
        end
      end
    end
  end

  describe ".for_year" do
    context "when an academic cycle exists for the given year" do
      it "returns the matching academic cycle" do
        academic_cycle
        expect(described_class.for_year(AcademicYearHelper.current_academic_year)).to eq(academic_cycle)
      end
    end

    context "when no academic cycle exists for the given year" do
      it "returns nil" do
        expect(described_class.for_year(2023)).to be_nil
      end
    end
  end
end
