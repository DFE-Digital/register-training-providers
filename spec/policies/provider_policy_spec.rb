require "rails_helper"

RSpec.describe ProviderPolicy do
  subject { described_class }

  permissions :show? do
    it "permits access if the provider is kept" do
      provider = create(:provider)
      expect(subject).to permit(build(:user), provider)
    end

    it "denies access if the provider is discarded" do
      provider = create(:provider, :discarded)
      expect(subject).not_to permit(build(:user), provider)
    end
  end

  permissions :edit?, :update? do
    it "permits access if the provider is kept and not archived" do
      provider = create(:provider)
      expect(subject).to permit(build(:user), provider)
    end

    it "denies access if the provider is discarded" do
      provider = create(:provider, :discarded)
      expect(subject).not_to permit(build(:user), provider)
    end

    it "denies access if the provider is archived" do
      provider = create(:provider, :archived)
      expect(subject).not_to permit(build(:user), provider)
    end
  end

  permissions :create? do
    it "permits access if the provider is a new record" do
      provider = build(:provider)
      expect(subject).to permit(build(:user), provider)
    end

    it "denies access if the provider is persisted" do
      provider = create(:provider)
      expect(subject).not_to permit(build(:user), provider)
    end
  end
end
