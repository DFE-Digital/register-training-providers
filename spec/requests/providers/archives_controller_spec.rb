RSpec.describe "Provider deletion rate limit", type: :request do
  include DfESignInUserHelper

  let(:user) { create(:user) }
  let(:providers_to_archive) { create_list :provider, 3 }
  let(:provider_fails_to_be_archived) { create(:provider) }

  before do
    user_exists_in_dfe_sign_in(user:)
    get "/auth/dfe/callback"
  end

  after do
    OmniAuth.config.mock_auth.clear
  end

  it "allows 3 archives within 3 minutes but blocks the 4th" do
    Timecop.freeze(Time.zone.now) do
      providers_to_archive.each do |provider_to_archive|
        put provider_archive_path(provider_to_archive)
        expect(response).to have_http_status(:redirect)
      end

      expect(Rails.logger).to receive(:warn).with(
        event: "too_many_requests",
        user_id: user.id,
        controller: "Providers::ArchivesController",
        action: "update",
        path: "/providers/#{provider_fails_to_be_archived.id}/archive",
      )

      put provider_archive_path(provider_fails_to_be_archived)

      expect(response).to have_http_status(:too_many_requests)
    end
  end
end
