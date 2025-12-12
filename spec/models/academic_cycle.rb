require "rails_helper"

RSpec.describe AcademicCycle, type: :model do
  let(:academic_cycle) { create(:academic_cycle, duration: Date.new(2025, 8, 1)...Date.new(2026, 7, 31)) }

  it { is_expected.to be_kept }

  context "academic_cycle is discarded" do
    before do
      academic_cycle.discard!
    end

    it "the user is discarded" do
      expect(academic_cycle).to be_discarded
    end
  end

  describe "associations" do
    it { is_expected.to have_many(:partnership_academic_cycles) }
    it { is_expected.to have_many(:partnerships).through(:partnership_academic_cycles) }
  end

  describe "#current?" do
    context "when it is the current academic_cyle" do
      it "is expected to be true" do
        Timecop.freeze(2025, 9, 1) do
          expect(academic_cycle.current?).to be true
        end
      end
    end

    context "when it is not the current academic_cyle" do
      it "is expected to be false" do
        Timecop.freeze(2024, 1, 9) do
          expect(academic_cycle.current?).to be false
        end
      end
    end
  end

  describe "#next?" do
    context "when it is the previous academic_cyle" do
      it "is expected to be true" do
        Timecop.freeze(2024, 9, 1) do
          expect(academic_cycle.next?).to be true
        end
      end
    end

    context "when it is not the previous academic_cyle" do
      it "is expected to be false" do
        Timecop.freeze(2025, 9, 1) do
          expect(academic_cycle.next?).to be false
        end
      end
    end
  end

  describe "#last??" do
    context "when it is the next academic_cyle" do
      it "is expected to be true" do
        Timecop.freeze(2026, 9, 1) do
          expect(academic_cycle.last?).to be true
        end
      end
    end

    context "when it is not the current academic_cyle" do
      it "is expected to be false" do
        Timecop.freeze(2025, 9, 1) do
          expect(academic_cycle.last?).to be false
        end
      end
    end
  end
end
