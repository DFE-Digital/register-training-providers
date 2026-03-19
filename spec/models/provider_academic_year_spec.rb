require "rails_helper"

RSpec.describe ProviderAcademicYear, type: :model do
  let(:provider_academic_year) { create(:provider_academic_year) }

  it { is_expected.to be_audited }
  it { is_expected.to be_kept }

  context "provider_academic_year is discarded" do
    before do
      provider_academic_year.discard!
    end

    it "the provider_academic_year is discarded" do
      expect(provider_academic_year).to be_discarded
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:provider) }
    it { is_expected.to belong_to(:academic_year) }
  end
end
