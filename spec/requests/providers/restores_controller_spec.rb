RSpec.describe "Provider restoring", type: :request do
  include DfESignInUserHelper

  let(:user) { create(:user) }
  let(:provider) { create(:provider, :archived) }

  before do
    user_exists_in_dfe_sign_in(user:)
    get "/auth/dfe/callback"
  end

  after do
    OmniAuth.config.mock_auth.clear
  end

  it "records only one completed restore change when submitted twice" do
    # The second request is a genuine double-submit: Pundit's restore? policy
    # rejects a provider that is no longer archived, so without this stub the
    # request never reaches the controller body and the `next unless archived?`
    # row-lock guard goes untested. Bypass authorisation to prove the guard is
    # what de-duplicates the restore.
    allow_any_instance_of(ProviderPolicy).to receive(:restore?).and_return(true)

    put provider_restore_path(provider)
    expect(response).to have_http_status(:redirect)

    put provider_restore_path(provider)
    expect(response).to have_http_status(:redirect)

    provider.reload

    expect(provider).not_to be_archived
    expect(provider.provider_changes
                   .where(source: %w[requested system])
                   .for_attribute("status")
                   .completed.count).to eq(1)
  end
end
