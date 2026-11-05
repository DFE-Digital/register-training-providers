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

    context "when the status wizard state has been lost" do
      it "redirects to the wizard rather than reporting a successful confirmation" do
        expect {
          patch provider_change_update_step_path(
            provider_id: provider.id,
            field: "status",
            step: "check-your-answers"
          ), params: {}
        }.not_to(change { ProviderChange.count })

        expect(response).not_to redirect_to(provider_path(provider))
        expect(flash[:success]).to be_nil
      end
    end

    context "when the status wizard has partial state" do
      before do
        patch provider_change_update_step_path(
          provider_id: provider.id,
          field: "status",
          step: "new-status"
        ), params: { new_status: { new_status: "inactive" } }
      end

      it "preserves the state instead of clearing it as a duplicate confirmation" do
        patch provider_change_update_step_path(
          provider_id: provider.id,
          field: "status",
          step: "check-your-answers"
        ), params: {}

        expect(response).not_to redirect_to(provider_path(provider))
        expect(flash[:success]).to be_nil

        get provider_change_step_path(provider_id: provider.id, field: "status", step: "reasons")

        expect(response).to have_http_status(:ok)
      end
    end
  end
end
