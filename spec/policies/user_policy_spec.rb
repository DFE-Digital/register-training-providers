require "rails_helper"

RSpec.describe UserPolicy do
  subject { described_class }

  permissions :show? do
    it "permits access if the user is kept" do
      user = create(:user)
      expect(subject).to permit(build(:user), user)
    end

    it "denies access if the user is discarded" do
      user = create(:user, :discarded)
      expect(subject).not_to permit(build(:user), user)
    end
  end

  permissions :edit?, :update? do
    it "permits access if the user is kept" do
      user = create(:user)
      expect(subject).to permit(build(:user), user)
    end

    it "denies access if the user is discarded" do
      user = create(:user, :discarded)
      expect(subject).not_to permit(build(:user), user)
    end
  end

  permissions :create? do
    it "permits access if the user is a new record" do
      user = build(:user)
      expect(subject).to permit(build(:user), user)
    end

    it "denies access if the user is persisted" do
      user = create(:user)
      expect(subject).not_to permit(build(:user), user)
    end
  end

  describe ".policy_scope" do
    let(:user) { create(:user, api_user:) }
    let(:other_user) { create(:user) }

    context "for an api user" do
      let(:api_user) { true }

      it "returns kept api clients created by the user" do
        expect(Pundit.policy_scope(user, User)).to eq []
      end
    end

    context "for a support user" do
      let(:api_user) { false }

      it "returns all kept api clients" do
        expect(Pundit.policy_scope(user, User)).to contain_exactly user, other_user
      end
    end
  end
end
