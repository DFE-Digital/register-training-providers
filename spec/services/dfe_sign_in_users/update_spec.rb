require "rails_helper"

describe DfESignInUsers::Update do
  describe "#call" do
    it "sets the dfe sign in uid on first link" do
      user = create(:user, dfe_sign_in_uid: nil)

      sign_in_user = DfESignInUser.new(
        email: user.email,
        dfe_sign_in_uid: "dfe-123",
        first_name: "Test",
        last_name: "User",
      )

      described_class.call(
        user:,
        sign_in_user:,
      )

      expect(user.reload.dfe_sign_in_uid).to eq("dfe-123")
    end

    it "does not replace an existing dfe sign in uid" do
      user = create(:user, dfe_sign_in_uid: "existing-dfe-123")

      sign_in_user = DfESignInUser.new(
        email: user.email,
        dfe_sign_in_uid: "different-dfe-456",
        first_name: "Test",
        last_name: "User",
      )

      described_class.call(
        user:,
        sign_in_user:,
      )

      expect(user.reload.dfe_sign_in_uid).to eq("existing-dfe-123")
    end
  end
end
