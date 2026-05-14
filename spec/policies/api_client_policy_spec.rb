require "rails_helper"

RSpec.describe ApiClientPolicy do
  subject { described_class }
  let(:user) { create(:user) }
  let(:api_user) { create(:user, api_user: true) }
  let(:api_client) { create(:api_client, created_by: user) }
  let(:api_user_client) { create(:api_client, created_by: api_user) }
  let(:discarded_api_client) { create(:api_client, :discarded, created_by: user) }

  permissions :show?, :edit?, :update? do
    it "permits access if the api_client is kept" do
      expect(subject).to permit(user, api_client)
      expect(subject).to permit(user, api_user_client)
    end

    it "denies access if the api_client is discarded" do
      expect(subject).not_to permit(user, discarded_api_client)
    end
  end

  describe ".policy_scope" do
    context "for an api user" do
      it "returns kept api clients created by the user" do
        expect(Pundit.policy_scope(api_user, ApiClient)).to contain_exactly api_user_client
      end
    end

    context "for a support user" do
      it "returns all kept api clients" do
        expect(Pundit.policy_scope(user, ApiClient)).to contain_exactly api_client, api_user_client
      end
    end
  end
end
