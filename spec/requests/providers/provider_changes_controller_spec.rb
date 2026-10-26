require "rails_helper"

RSpec.describe "Provider changes", type: :request do
  include DfESignInUserHelper

  let(:user) { create(:user) }
  let(:provider) { create(:provider) }

  before do
    user_exists_in_dfe_sign_in(user:)
    get "/auth/dfe/callback"
  end

  after { OmniAuth.config.mock_auth.clear }

  describe "PATCH /providers/:provider_id/changes/:field/:step" do
    it "redirects to the previous step without saving when the wizard path is invalid" do
      expect {
        patch provider_change_update_step_path(
          provider_id: provider.id,
          field: "provider_type",
          step: "new-provider-type"
        ), params: { new_provider_type: { provider_type: "scitt" } }
      }.not_to(change { ProviderChange.count })

      expect(response).to redirect_to(
        provider_change_step_path(
          provider_id: provider.id,
          field: "provider_type",
          step: "effective-date"
        )
      )
    end

    it "does not save state, so a later GET still redirects to the first step" do
      patch provider_change_update_step_path(
        provider_id: provider.id,
        field: "provider_type",
        step: "new-provider-type"
      ), params: { new_provider_type: { provider_type: "scitt" } }

      get provider_change_step_path(
        provider_id: provider.id,
        field: "provider_type",
        step: "new-provider-type"
      )

      expect(response).to redirect_to(
        provider_change_step_path(
          provider_id: provider.id,
          field: "provider_type",
          step: "effective-date"
        )
      )
    end
  end
end
