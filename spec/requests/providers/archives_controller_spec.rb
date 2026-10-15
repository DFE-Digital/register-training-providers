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

RSpec.describe "Provider archiving", type: :request do
  include DfESignInUserHelper

  let(:user) { create(:user) }
  let(:provider) { create(:provider) }

  before do
    user_exists_in_dfe_sign_in(user:)
    get "/auth/dfe/callback"
  end

  after do
    OmniAuth.config.mock_auth.clear
  end

  it "records only one completed archive change when submitted twice" do
    # The second request is a genuine double-submit: Pundit's update? policy
    # rejects an already-archived provider (403), so without this stub the
    # request never reaches the controller body and the row-lock guard goes
    # untested. Bypass authorisation to prove the guard is what de-duplicates.
    allow_any_instance_of(ProviderPolicy).to receive(:update?).and_return(true)

    put provider_archive_path(provider)
    expect(response).to have_http_status(:redirect)

    put provider_archive_path(provider)
    expect(response).to have_http_status(:redirect)

    provider.reload

    expect(provider).to be_archived
    expect(provider.provider_changes
                   .where(source: %w[requested system])
                   .for_attribute("status")
                   .completed.count).to eq(1)
  end

  context "when the provider is inactive" do
    let(:provider) { create(:provider, :with_current_inactive_period) }

    it "closes the open inactive period and records the pre-archive status" do
      put provider_archive_path(provider)

      expect(response).to have_http_status(:redirect)

      provider.reload

      expect(provider).to be_archived
      expect(provider.current_inactive_period).to be_nil
      expect(provider.inactive_periods.sole["end_date"]).to eq(Time.zone.yesterday.to_s)
      # The baseline must capture the status the provider actually held; closing
      # the period before recording would have baselined it as active.
      expect(provider.provider_changes.baseline.for_attribute("status").sole.value)
        .to eq({ "status" => "inactive" })
    end
  end

  context "when the provider is off-boarded" do
    let(:provider) { create(:provider, :with_current_offboarded_period) }

    it "closes the open off-boarded period" do
      put provider_archive_path(provider)

      expect(response).to have_http_status(:redirect)

      provider.reload

      expect(provider).to be_archived
      expect(provider.open_offboarded_period).to be_nil
      expect(provider.inactive_periods.sole["end_date"]).to eq(Time.zone.yesterday.to_s)
    end
  end
end
