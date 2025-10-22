require "rails_helper"

RSpec.describe ContactPolicy do
  subject { described_class }

  let(:contact_with_discarded_provider) { create(:contact, provider: discarded_provider) }
  let(:contact_with_kept_provider) { create(:contact) }
  let(:discarded_provider) { create(:provider, :discarded) }

  permissions :index? do
    it "permits access if the provider is kept" do
      expect(subject).to permit(build(:user), contact_with_kept_provider)
    end

    it "denies access if the provider is discarded" do
      expect(subject).not_to permit(build(:user), contact_with_discarded_provider)
    end
  end
end
