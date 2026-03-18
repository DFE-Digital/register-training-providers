require "rails_helper"

RSpec.describe ProviderAcademicCycle, type: :model do
  let(:provider_academic_cycle) { create(:provider_academic_cycle) }

  it { is_expected.to be_audited }
  it { is_expected.to be_kept }

  context "provider_academic_cycle is discarded" do
    before do
      provider_academic_cycle.discard!
    end

    it "the provider_academic_cycle is discarded" do
      expect(provider_academic_cycle).to be_discarded
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:provider) }
    it { is_expected.to belong_to(:academic_cycle) }
  end
end
