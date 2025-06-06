require "rails_helper"

describe DfESignInUser do
  describe ".load_from_session" do
    it "returns the DfE User when the user has signed in and has been recently active" do
      session = { "dfe_sign_in_user" => { "last_active_at" => Time.zone.now } }

      signin_user = DfESignInUser.load_from_session(session)
      expect(signin_user).not_to be_nil
    end

    it "returns nil when the user has signed in and has not been recently active" do
      session = { "dfe_sign_in_user" => { "last_active_at" => 1.day.ago } }

      signin_user = DfESignInUser.load_from_session(session)

      expect(signin_user).to be_nil
    end

    it "returns nil when the user has not signed in" do
      session = { "dfe_sign_in_user" => nil }

      signin_user = DfESignInUser.load_from_session(session)

      expect(signin_user).to be_nil
    end

    it "returns nil when the user does not have a last active timestamp" do
      session = { "dfe_sign_in_user" => { "last_active_at" => nil } }

      signin_user = DfESignInUser.load_from_session(session)

      expect(signin_user).to be_nil
    end
  end

  describe ".end_session!" do
    it "delete the dfe_sign_in_user from session" do
      session = { "dfe_sign_in_user" => nil }

      DfESignInUser.end_session!(session)
      expect(session).to be_empty
    end
  end

  describe "#logout_url" do
    it "returns the dfe logout url" do
      session = {
        "dfe_sign_in_user" => {
          "first_name" => "Example",
          "last_name" => "User",
          "email" => "example_user@example.com",
          "last_active_at" => 1.hour.ago,
          "dfe_sign_in_uid" => "123",
          "id_token" => "123",
          "provider" => "dfe",
        },
      }
      dfe_sign_in_user = described_class.load_from_session(session)
      request = instance_double(ActionDispatch::Request, base_url: "dfe_url")

      expect(dfe_sign_in_user.logout_url(request)).to eq(
        "https://test-oidc.signin.education.gov.uk/session/end?id_token_hint=" \
        "123&post_logout_redirect_uri=dfe_url%2Fauth%2Fdfe%2Fsign-out",
      )
    end
  end
end
