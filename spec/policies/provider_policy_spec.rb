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

  describe ".policy_scope" do
    let(:user) { create(:user, api_user:) }
    let(:provider) { create(:provider) }

    context "for an api user" do
      let(:api_user) { true }

      it "returns kept api clients created by the user" do
        expect(Pundit.policy_scope(user, Provider)).to eq []
      end
    end

    context "for a support user" do
      let(:api_user) { false }

      it "returns all kept api clients" do
        expect(Pundit.policy_scope(user, Provider)).to contain_exactly provider
      end
    end
  end
end
