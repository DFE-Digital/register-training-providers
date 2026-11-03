require "rails_helper"

RSpec.describe "API client delete and revoke role access", type: :request do
  include DfESignInUserHelper

  let(:reg) { create(:user, :reg) }
  let(:api_user) { create(:user, api_user: true) }
  let(:other_api_user) { create(:user, api_user: true) }

  describe "deleting an API client" do
    it "denies RO" do
      api_client = create(:api_client, created_by: reg)
      sign_in_as(create(:user, :ro))

      get api_client_delete_path(api_client)
      expect(response).to have_http_status(:forbidden)

      delete api_client_delete_path(api_client)
      expect(response).to have_http_status(:forbidden)
      expect(api_client.reload).not_to be_discarded
    end

    it "denies an API user who did not create it" do
      api_client = create(:api_client, created_by: other_api_user)
      sign_in_as(api_user)

      get api_client_delete_path(api_client)
      expect(response).to have_http_status(:forbidden)

      delete api_client_delete_path(api_client)
      expect(response).to have_http_status(:forbidden)
      expect(api_client.reload).not_to be_discarded
    end

    it "permits the API user who created it" do
      api_client = create(:api_client, created_by: api_user)
      sign_in_as(api_user)

      delete api_client_delete_path(api_client)

      expect(response).to have_http_status(:redirect)
      expect(api_client.reload).to be_discarded
    end

    it "permits REG for any client" do
      api_client = create(:api_client, created_by: other_api_user)
      sign_in_as(reg)

      delete api_client_delete_path(api_client)

      expect(response).to have_http_status(:redirect)
      expect(api_client.reload).to be_discarded
    end
  end

  describe "revoking an API client" do
    it "denies RO" do
      api_client = create(:api_client, :with_authentication_token, created_by: reg)
      sign_in_as(create(:user, :ro))

      get api_client_revoke_path(api_client)
      expect(response).to have_http_status(:forbidden)

      delete api_client_revoke_path(api_client)
      expect(response).to have_http_status(:forbidden)
    end

    it "denies an API user who did not create it" do
      api_client = create(:api_client, :with_authentication_token, created_by: other_api_user)
      sign_in_as(api_user)

      delete api_client_revoke_path(api_client)

      expect(response).to have_http_status(:forbidden)
    end

    it "permits the API user who created it" do
      api_client = create(:api_client, :with_authentication_token, created_by: api_user)
      sign_in_as(api_user)

      delete api_client_revoke_path(api_client)

      expect(response).to have_http_status(:redirect)
    end
  end
end
