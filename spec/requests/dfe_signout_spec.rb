require "rails_helper"

RSpec.describe "DfE Sign out", type: :request do
  include DfESignInUserHelper

  let(:user) { create(:user) }

  before do
    user_exists_in_dfe_sign_in(user:)
  end

  after do
    OmniAuth.config.mock_auth.clear
  end

  describe "GET /auth/dfe/sign-out" do
    it "clears the session when signing out" do
      get "/auth/dfe/callback"

      expect(session["dfe_sign_in_user"]).to be_present

      old_session_cookie = response.cookies["_register_of_training_providers_session"]

      get "/auth/dfe/sign-out"

      new_session_cookie = response.cookies["_register_of_training_providers_session"]

      expect(new_session_cookie).not_to eq(old_session_cookie)
    end
  end
end
