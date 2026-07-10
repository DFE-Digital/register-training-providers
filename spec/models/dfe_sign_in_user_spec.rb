require "rails_helper"

describe DfESignInUser do
  describe ".load_from_session" do
    it "returns the DfE User when the user has signed in and has been recently active" do
      session = { "dfe_sign_in_user" => { "last_active_at" => Time.zone.now } }

      sign_in_user = described_class.load_from_session(session)

      expect(sign_in_user).not_to be_nil
    end

    it "returns nil when the user has signed in and has not been recently active" do
      session = { "dfe_sign_in_user" => { "last_active_at" => 1.day.ago } }

      sign_in_user = described_class.load_from_session(session)

      expect(sign_in_user).to be_nil
    end

    it "returns nil when the user has not signed in" do
      session = { "dfe_sign_in_user" => nil }

      sign_in_user = described_class.load_from_session(session)

      expect(sign_in_user).to be_nil
    end

    it "returns nil when the user does not have a last active timestamp" do
      session = { "dfe_sign_in_user" => { "last_active_at" => nil } }

      sign_in_user = described_class.load_from_session(session)

      expect(sign_in_user).to be_nil
    end
  end

  describe ".end_session!" do
    it "deletes the dfe sign in user from session" do
      session = {
        "dfe_sign_in_user" => {
          "email" => "example@example.com",
        },
      }

      described_class.end_session!(session)

      expect(session["dfe_sign_in_user"]).to be_nil
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

  describe "#user" do
    context "when the user has a matching dfe sign in uid" do
      it "finds the user by dfe sign in uid" do
        user = create(:user, dfe_sign_in_uid: "dfe-123")

        sign_in_user = described_class.new(
          email: user.email,
          dfe_sign_in_uid: "dfe-123",
          first_name: "Test",
          last_name: "User",
        )

        expect(sign_in_user.user).to eq(user)
      end
    end

    context "when the user has no dfe sign in uid" do
      it "finds the user by email to allow first time linking" do
        user = create(
          :user,
          email: "test@education.gov.uk",
          dfe_sign_in_uid: nil,
        )

        sign_in_user = described_class.new(
          email: user.email,
          dfe_sign_in_uid: "dfe-123",
          first_name: "Test",
          last_name: "User",
        )

        expect(sign_in_user.user).to eq(user)
      end
    end

    context "when the email matches but the user is already linked to another dfe account" do
      it "logs a warning and does not return the user by email fallback" do
        create(
          :user,
          email: "test@education.gov.uk",
          dfe_sign_in_uid: "existing-dfe-123",
        )

        sign_in_user = described_class.new(
          email: "test@education.gov.uk",
          dfe_sign_in_uid: "different-dfe-456",
          first_name: "Test",
          last_name: "User",
        )

        expect(sign_in_user.user).to be_nil
      end
    end
  end
end
