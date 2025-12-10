require "rails_helper"

RSpec.describe PartnershipAcademicCycle, type: :model do
  let(:partnership_academic_cycle) { create(:partnership_academic_cycle) }

  it { is_expected.to be_audited }
  it { is_expected.to be_kept }

  context "partnership_academic_cycle is discarded" do
    before do
      partnership_academic_cycle.discard!
    end

    it "the user is discarded" do
      expect(partnership_academic_cycle).to be_discarded
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:partnership) }
    it { is_expected.to belong_to(:academic_cycle) }
  end
end
