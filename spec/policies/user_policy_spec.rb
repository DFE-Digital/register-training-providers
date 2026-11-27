require "rails_helper"

RSpec.describe UserPolicy do
  subject { described_class }

  let(:reg) { build(:user, :reg) }
  let(:mr) { build(:user, :mr) }
  let(:bat) { build(:user, :bat) }
  let(:ro) { build(:user, :ro) }

  permissions :index? do
    it "permits a REG user" do
      expect(subject).to permit(reg, build(:user))
    end

    it "denies MR, BAT and RO users" do
      [mr, bat, ro].each do |user|
        expect(subject).not_to permit(user, build(:user))
      end
    end
  end

  permissions :show? do
    it "permits a REG user for a kept user" do
      expect(subject).to permit(reg, create(:user))
    end

    it "denies a discarded user" do
      expect(subject).not_to permit(reg, create(:user, :discarded))
    end

    it "denies non-REG users" do
      [mr, bat, ro].each do |user|
        expect(subject).not_to permit(user, create(:user))
      end
    end
  end

  permissions :edit?, :update?, :destroy? do
    it "permits a REG user to manage another kept user" do
      expect(subject).to permit(reg, create(:user))
    end

    it "denies editing self" do
      expect(subject).not_to permit(reg, reg)
    end

    it "denies editing a discarded user" do
      expect(subject).not_to permit(reg, create(:user, :discarded))
    end

    it "denies editing a system admin" do
      expect(subject).not_to permit(reg, create(:user, system_admin: true))
    end

    it "denies non-REG users" do
      [mr, bat, ro].each do |user|
        expect(subject).not_to permit(user, create(:user))
      end
    end
  end

  permissions :create? do
    it "permits a REG user for a new record" do
      expect(subject).to permit(reg, build(:user))
    end

    it "denies a persisted record" do
      expect(subject).not_to permit(reg, create(:user))
    end

    it "denies non-REG users" do
      [mr, bat, ro].each do |user|
        expect(subject).not_to permit(user, build(:user))
      end
    end
  end

  describe ".policy_scope" do
    let!(:kept_user) { create(:user) }
    let!(:discarded_user) { create(:user, :discarded) }

    it "returns kept users for REG" do
      expect(Pundit.policy_scope(reg, User)).to contain_exactly(kept_user)
    end

    it "returns no users for MR, BAT, RO and API users" do
      [mr, bat, ro, build(:user, api_user: true)].each do |user|
        expect(Pundit.policy_scope(user, User)).to be_empty
      end
    end
  end
end
