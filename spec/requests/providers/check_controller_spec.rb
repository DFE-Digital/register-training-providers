require "rails_helper"

RSpec.describe "Provider confirm step", type: :request do
  include DfESignInUserHelper

  let(:user) { create(:user) }

  before do
    user_exists_in_dfe_sign_in(user:)
    get "/auth/dfe/callback"

    allow_any_instance_of(ProviderCreation::SessionManager)
      .to receive(:load_provider).and_return(build(:provider))
  end

  after do
    OmniAuth.config.mock_auth.clear
  end

  it "renders the confirm step when the request carries a stale provider_id" do
    get new_provider_confirm_path, params: { provider_id: SecureRandom.uuid }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Check your answers")
  end
end
