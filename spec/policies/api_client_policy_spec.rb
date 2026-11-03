require "rails_helper"

RSpec.describe ApiClientPolicy do
  subject { described_class }

  let(:reg) { build(:user, :reg) }
  let(:mr) { build(:user, :mr) }
  let(:bat) { build(:user, :bat) }
  let(:ro) { build(:user, :ro) }
  let(:owner) { create(:user, :reg) }
  let(:api_user) { create(:user, api_user: true) }
  let(:api_client) { create(:api_client, created_by: owner) }
  let(:api_user_client) { create(:api_client, created_by: api_user) }
  let(:discarded_api_client) { create(:api_client, :discarded, created_by: owner) }

  permissions :index? do
    it "permits REG and API users" do
      expect(subject).to permit(reg, ApiClient)
      expect(subject).to permit(api_user, ApiClient)
    end

    it "denies MR, BAT and RO users" do
      [mr, bat, ro].each do |user|
        expect(subject).not_to permit(user, ApiClient)
      end
    end
  end

  permissions :show?, :edit?, :update?, :destroy? do
    it "permits REG on any kept client" do
      expect(subject).to permit(reg, api_client)
      expect(subject).to permit(reg, api_user_client)
    end

    it "permits an API user on their own client" do
      expect(subject).to permit(api_user, api_user_client)
    end

    it "denies an API user on another client" do
      expect(subject).not_to permit(api_user, api_client)
    end

    it "denies MR, BAT and RO users" do
      [mr, bat, ro].each do |user|
        expect(subject).not_to permit(user, api_client)
      end
    end

    it "denies a discarded client" do
      expect(subject).not_to permit(reg, discarded_api_client)
    end
  end

  permissions :create? do
    it "permits REG and API users for a new record" do
      expect(subject).to permit(reg, build(:api_client))
      expect(subject).to permit(api_user, build(:api_client))
    end

    it "denies MR, BAT and RO users" do
      [mr, bat, ro].each do |user|
        expect(subject).not_to permit(user, build(:api_client))
      end
    end

    it "denies a persisted client" do
      expect(subject).not_to permit(reg, api_client)
    end
  end

  permissions :confirm? do
    it "permits an API user for their own kept client" do
      expect(subject).to permit(api_user, api_user_client)
    end

    it "denies an API user for another client" do
      expect(subject).not_to permit(api_user, api_client)
    end

    it "denies a discarded client" do
      expect(subject).not_to permit(api_user, discarded_api_client)
    end

    it "denies a creator who has been demoted out of REG" do
      client = create(:api_client, created_by: owner)
      owner.update!(role: UserRoleEnum::MR)

      expect(subject).not_to permit(owner, client)
    end
  end

  describe ".policy_scope" do
    it "returns all kept clients for REG" do
      expect(Pundit.policy_scope(reg, ApiClient)).to contain_exactly(api_client, api_user_client)
    end

    it "returns only their own clients for an API user" do
      expect(Pundit.policy_scope(api_user, ApiClient)).to contain_exactly(api_user_client)
    end

    it "returns no clients for MR, BAT and RO" do
      [mr, bat, ro].each do |user|
        expect(Pundit.policy_scope(user, ApiClient)).to be_empty
      end
    end
  end
end
