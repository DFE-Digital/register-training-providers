RSpec.describe "Provider deletion rate limit", type: :request do
  include DfESignInUserHelper

  let(:user) { create(:user) }
  let(:providers_to_delete) { create_list :provider, 3 }
  let(:provider_fails_to_be_deleted) { create(:provider) }

  before do
    user_exists_in_dfe_sign_in(user:)
    get "/auth/dfe/callback"
  end

  after do
    OmniAuth.config.mock_auth.clear
  end

  it "allows 3 deletes within 3 minutes but blocks the 4th" do
    Timecop.freeze(Time.zone.now) do
      providers_to_delete.each do |provider_to_delete|
        delete provider_delete_path(provider_to_delete)
        expect(response).to have_http_status(:redirect)
      end

      expect(Rails.logger).to receive(:warn).with(
        event: "too_many_requests",
        user_id: user.id,
        controller: "Providers::DeletesController",
        action: "destroy",
        path: "/providers/#{provider_fails_to_be_deleted.id}/delete",
      )

      delete provider_delete_path(provider_fails_to_be_deleted)

      expect(response).to have_http_status(:too_many_requests)
    end
  end
end
