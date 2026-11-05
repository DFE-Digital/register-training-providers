RSpec.describe "Provider archiving rate limit", type: :request do
  include DfESignInUserHelper

  let(:user) { create(:user) }
  let(:providers_to_archive) { create_list :provider, 3, :with_current_inactive_period }
  let(:provider_fails_to_be_archived) { create(:provider, :with_current_inactive_period) }

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
  let(:provider) { create(:provider, :with_current_inactive_period) }

  before do
    user_exists_in_dfe_sign_in(user:)
    get "/auth/dfe/callback"
  end

  after do
    OmniAuth.config.mock_auth.clear
  end

  it "records only one completed archive change when submitted twice" do
    allow_any_instance_of(ProviderPolicy).to receive(:archive?).and_return(true)

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
    it "closes the open inactive period and records the pre-archive status" do
      put provider_archive_path(provider)

      expect(response).to have_http_status(:redirect)

      provider.reload

      expect(provider).to be_archived
      expect(provider.current_inactive_period).to be_nil
      expect(provider.inactive_periods.sole["end_date"]).to eq(Time.zone.yesterday.to_s)
      expect(provider.provider_changes.requested.for_attribute("status").sole.value)
        .to eq({ "status" => "archived", "previous_status" => "inactive" })
      expect(provider.provider_changes.baseline.for_attribute("status").sole.value)
        .to eq({ "status" => "inactive" })
    end
  end

  context "when the inactive period began today" do
    let(:provider) do
      create(:provider, inactive_periods: [{ start_date: Time.zone.today, end_date: nil }])
    end

    it "ends the period today because it cannot end before it started" do
      put provider_archive_path(provider)

      expect(response).to have_http_status(:redirect)
      expect(provider.reload.inactive_periods.sole["end_date"]).to eq(Time.zone.today.to_s)
    end
  end

  context "when the provider is active" do
    let(:provider) { create(:provider) }

    it "does not archive the provider" do
      put provider_archive_path(provider)

      expect(response).to have_http_status(:forbidden)
      expect(provider.reload).not_to be_archived
    end
  end

  context "when the provider is off-boarded" do
    let(:provider) { create(:provider, :with_current_offboarded_period) }

    it "does not archive the provider" do
      put provider_archive_path(provider)

      expect(response).to have_http_status(:forbidden)
      expect(provider.reload).not_to be_archived
      expect(provider.open_offboarded_period).to be_present
    end

    it "does not archive it when the policy was evaluated against the pre-offboarding record" do
      allow_any_instance_of(ProviderPolicy).to receive(:archive?).and_return(true)

      put provider_archive_path(provider)

      expect(response).to have_http_status(:redirect)
      expect(flash[:alert]).to eq("The provider could not be archived because its status changed")

      follow_redirect!
      expect(Capybara.string(response.body)).to have_notification_banner(
        "Important",
        "The provider could not be archived because its status changed"
      )

      provider.reload

      expect(provider).not_to be_archived
      expect(provider.open_offboarded_period).to be_present
      expect(provider.provider_changes.where(source: %w[requested system]).for_attribute("status")).to be_empty
    end
  end

  context "when the provider is discarded between authorisation and the row lock" do
    let(:provider) { create(:provider, :with_current_inactive_period) }

    it "does not archive the discarded provider" do
      allow_any_instance_of(ProviderPolicy).to receive(:archive?).and_return(true)

      provider.discard!

      put provider_archive_path(provider)

      expect(response).to have_http_status(:redirect)

      provider.reload

      expect(provider).to be_discarded
      expect(provider).not_to be_archived
      expect(provider.provider_changes.for_attribute("status")).to be_empty
    end
  end
end
