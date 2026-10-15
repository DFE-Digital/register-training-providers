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

  context "when the provider was archived from inactive" do
    let(:provider) { create(:provider, :with_current_inactive_period) }

    it "restores the provider to inactive and reopens the period" do
      put provider_archive_path(provider)
      expect(response).to have_http_status(:redirect)

      put provider_restore_path(provider)
      expect(response).to have_http_status(:redirect)

      provider.reload

      expect(provider).not_to be_archived
      expect(provider.status).to eq("inactive")
      expect(provider.current_inactive_period).to be_present
      expect(provider.current_inactive_period["end_date"]).to be_nil
      expect(provider.provider_changes.requested.for_attribute("status").order(:created_at).last.value)
        .to eq({ "status" => "inactive", "previous_status" => "archived" })
    end
  end

  context "when the provider was archived from offboarded" do
    let(:provider) { create(:provider, :with_current_offboarded_period) }

    before do
      provider.open_offboarded_period["end_date"] = Time.zone.yesterday.to_s
      provider.save!
      provider.archive!
      Providers::RecordStatusChange.call(
        provider: provider,
        status_value: "archived",
        previous_status: "offboarded"
      )
    end

    it "restores the provider to offboarded and reopens the period" do
      put provider_restore_path(provider)

      expect(response).to have_http_status(:redirect)

      provider.reload

      expect(provider).not_to be_archived
      expect(provider.status).to eq("offboarded")
      expect(provider.open_offboarded_period).to be_present
    end
  end

  context "when the archive records inactive but there is no closed period" do
    let(:provider) { create(:provider) }

    before do
      provider.archive!
      Providers::RecordStatusChange.call(
        provider: provider,
        status_value: "archived",
        previous_status: "inactive"
      )
    end

    it "restores to active without inventing an inactive period" do
      put provider_restore_path(provider)

      expect(response).to have_http_status(:redirect)

      provider.reload

      expect(provider).not_to be_archived
      expect(provider.current_inactive_period).to be_nil
      expect(provider.status).to eq("active")
    end
  end

  context "when the latest closed period ended before the archive change" do
    let(:period_end) { 3.years.ago.to_date }
    let(:provider) do
      create(
        :provider,
        inactive_periods: [{ start_date: 4.years.ago.to_date, end_date: period_end }]
      )
    end

    before do
      provider.archive!
      Providers::RecordStatusChange.call(
        provider: provider,
        status_value: "archived",
        previous_status: "inactive"
      )
    end

    it "leaves the unrelated earlier period closed" do
      put provider_restore_path(provider)

      expect(response).to have_http_status(:redirect)

      provider.reload

      expect(provider).not_to be_archived
      expect(provider.current_inactive_period).to be_nil
      expect(provider.inactive_periods.sole["end_date"]).to eq(period_end.to_s)
    end
  end

  context "when the archive has no previous status recorded" do
    let(:provider) { create(:provider, :archived) }

    it "restores the provider to active" do
      put provider_restore_path(provider)

      expect(response).to have_http_status(:redirect)

      expect(provider.reload.status).to eq("active")
    end
  end

  context "when the provider is discarded between authorisation and the row lock" do
    let(:provider) { create(:provider, :archived) }

    it "does not restore the discarded provider" do
      allow_any_instance_of(ProviderPolicy).to receive(:restore?).and_return(true)

      provider.discard!

      put provider_restore_path(provider)

      expect(response).to have_http_status(:redirect)
      expect(flash[:alert]).to eq("The provider could not be restored because its status changed")
      expect(flash[:success]).to be_nil

      provider.reload

      expect(provider).to be_discarded
      expect(provider).to be_archived
      expect(provider.provider_changes.for_attribute("status")).to be_empty
    end
  end

  context "when the provider is restored between authorisation and the row lock" do
    let(:provider) { create(:provider, :archived) }

    it "does not claim success when there was nothing left to restore" do
      allow_any_instance_of(ProviderPolicy).to receive(:restore?).and_return(true)

      provider.restore!

      put provider_restore_path(provider)

      expect(response).to have_http_status(:redirect)
      expect(flash[:alert]).to eq("The provider could not be restored because its status changed")
      expect(flash[:success]).to be_nil

      follow_redirect!
      expect(Capybara.string(response.body)).to have_notification_banner(
        "Important",
        "The provider could not be restored because its status changed"
      )
    end
  end
end
