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
end
