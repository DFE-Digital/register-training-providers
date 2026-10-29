RSpec.describe "Provider deletion rate limit", type: :request do
  include DfESignInUserHelper

  let(:user) { create(:user) }
  let(:providers_to_delete) { create_list :provider, 3, :archived }
  let(:provider_fails_to_be_deleted) { create(:provider, :archived) }

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

RSpec.describe "Provider deletion", type: :request do
  include DfESignInUserHelper

  let(:user) { create(:user) }

  before do
    user_exists_in_dfe_sign_in(user:)
    get "/auth/dfe/callback"
  end

  after do
    OmniAuth.config.mock_auth.clear
  end

  it "soft-deletes an archived provider" do
    provider = create(:provider, :archived)

    delete provider_delete_path(provider)

    expect(response).to have_http_status(:redirect)
    expect(provider.reload).to be_discarded
  end

  it "soft-deletes only once when submitted twice" do
    provider = create(:provider, :archived)

    allow_any_instance_of(ProviderPolicy).to receive(:destroy?).and_return(true)

    delete provider_delete_path(provider)
    expect(response).to have_http_status(:redirect)

    expect { delete provider_delete_path(provider) }
      .not_to(change { provider.reload.discarded_at })
  end

  it "does not soft-delete a provider that is not archived" do
    provider = create(:provider)
    allow_any_instance_of(ProviderPolicy).to receive(:destroy?).and_return(true)

    delete provider_delete_path(provider)

    expect(response).to have_http_status(:redirect)
    expect(provider.reload).to be_kept
  end

  context "when the provider is restored between authorisation and the row lock" do
    let(:provider) { create(:provider, :archived) }

    it "does not claim success when there was nothing left to delete" do
      allow_any_instance_of(Provider).to receive(:with_lock).and_wrap_original do |original, &block|
        Provider.find(provider.id).restore!
        original.call(&block)
      end

      delete provider_delete_path(provider)

      expect(response).to have_http_status(:redirect)
      expect(flash[:alert]).to eq("The provider could not be deleted because its status changed")
      expect(flash[:success]).to be_nil
      expect(provider.reload).to be_kept
    end
  end

  context "when the provider is active" do
    let(:provider) { create(:provider) }

    it "does not delete the provider" do
      delete provider_delete_path(provider)

      expect(response).to have_http_status(:forbidden)
      expect(provider.reload).to be_kept
    end
  end

  context "when the provider is inactive" do
    let(:provider) { create(:provider, :with_current_inactive_period) }

    it "does not delete the provider" do
      delete provider_delete_path(provider)

      expect(response).to have_http_status(:forbidden)
      expect(provider.reload).to be_kept
    end
  end

  context "when the provider is offboarded" do
    let(:provider) { create(:provider, :with_current_offboarded_period) }

    it "does not delete the provider" do
      delete provider_delete_path(provider)

      expect(response).to have_http_status(:forbidden)
      expect(provider.reload).to be_kept
    end
  end
end
