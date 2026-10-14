require "rails_helper"

RSpec.describe "Provider creation", type: :request do
  include DfESignInUserHelper

  let(:user) { create(:user) }

  before do
    user_exists_in_dfe_sign_in(user:)
    get "/auth/dfe/callback"
  end

  after { OmniAuth.config.mock_auth.clear }

  def provider_details_params
    {
      operating_name: "Test Provider",
      legal_name: "Test Provider Ltd",
      ukprn: "12345678",
      urn: "123456",
      code: "ABC"
    }
  end

  def complete_onboarding_and_accreditation(accreditation_status:)
    post new_provider_onboarding_path, params: { provider: { onboarded_at_date_choice: "today" } }
    post new_provider_first_become_active_path, params: {
      provider: { onboarded_at: Date.current.to_s, first_active_at_date_choice: "same" }
    }
    post new_provider_is_the_provider_accredited_path, params: {
      provider: { accreditation_status: }
    }
  end

  def complete_details(provider_type: "hei")
    complete_onboarding_and_accreditation(accreditation_status: "unaccredited")
    post new_provider_type_path, params: { provider: { provider_type: } }
    post new_provider_details_path, params: { provider: provider_details_params }
  end

  describe "forged hidden values" do
    it "ignores an accreditation_status forged alongside the provider type" do
      complete_onboarding_and_accreditation(accreditation_status: "unaccredited")

      post new_provider_type_path, params: {
        provider: { provider_type: "scitt", accreditation_status: "accredited" }
      }
      post new_provider_details_path, params: { provider: provider_details_params }

      get new_provider_confirm_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("School-centred initial teacher training (SCITT)")
      expect(response.body).not_to include("Accreditation")
    end

    it "ignores provider_type and accreditation_status forged alongside the details" do
      complete_details(provider_type: "school")

      post new_provider_details_path, params: {
        provider: provider_details_params.merge(provider_type: "hei", accreditation_status: "accredited")
      }

      get new_provider_confirm_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("School")
      expect(response.body).not_to include("Higher education institution (HEI)")
      expect(response.body).not_to include("Accreditation")
    end

    it "ignores onboarded_at and first_active_at forged alongside the details" do
      complete_details

      post new_provider_details_path, params: {
        provider: provider_details_params.merge(
          onboarded_at: Date.new(2001, 2, 3),
          first_active_at: Date.new(2002, 4, 5)
        )
      }

      get new_provider_confirm_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(Date.current.to_fs(:govuk))
      expect(response.body).not_to include(Date.new(2001, 2, 3).to_fs(:govuk))
      expect(response.body).not_to include(Date.new(2002, 4, 5).to_fs(:govuk))
    end
  end

  describe "provider type validation" do
    it "accepts Other as a provider type and stores it" do
      complete_onboarding_and_accreditation(accreditation_status: "unaccredited")

      post new_provider_type_path, params: { provider: { provider_type: "other" } }
      post new_provider_details_path, params: { provider: provider_details_params }

      get new_provider_confirm_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Provider type")
      expect(response.body).to include("Other")
      expect(response.body).not_to include("Select a valid provider type")
    end
  end

  describe "provider type session guard" do
    it "redirects to the accreditation question when the session answer is missing" do
      post new_provider_type_path, params: { provider: { provider_type: "hei" } }

      expect(response).to redirect_to(new_provider_is_the_provider_accredited_path)
    end
  end

  describe "details session guard" do
    it "redirects to onboarding when the session is missing" do
      post new_provider_details_path, params: { provider: provider_details_params }

      expect(response).to redirect_to(new_provider_onboarding_path)
    end
  end

  describe "saving the provider" do
    before { complete_details }

    it "handles a duplicate submission without erroring" do
      post provider_confirm_path

      expect(response).to redirect_to(providers_path)
      expect(Provider.count).to eq(1)

      post provider_confirm_path

      expect(response).to redirect_to(providers_path)
      expect(Provider.count).to eq(1)
    end

    it "does not report success or create a row when the stored provider is invalid" do
      create(:provider, code: provider_details_params[:code])

      expect { post provider_confirm_path }.not_to(change { Provider.count })

      expect(response).to redirect_to(providers_setup_addresses_types_path)
      expect(flash[:success]).to be_nil
    end
  end

  describe "transactional save" do
    it "does not leave a partially created provider when a related record fails to save" do
      complete_onboarding_and_accreditation(accreditation_status: "accredited")
      post new_provider_type_path, params: { provider: { provider_type: "hei" } }
      post new_provider_details_path, params: { provider: provider_details_params }
      post new_provider_accreditation_path, params: {
        accreditation: {
          number: "1234",
          "start_date(3i)" => "1",
          "start_date(2i)" => "1",
          "start_date(1i)" => Date.current.year.to_s
        }
      }

      get new_provider_confirm_path
      expect(response).to have_http_status(:ok)

      allow_any_instance_of(AccreditationForm).to receive(:to_accreditation_attributes)
        .and_return({ number: nil, start_date: nil })

      expect { post provider_confirm_path }.not_to(change { Provider.count })

      expect(response).to have_http_status(:redirect)
    end
  end
end
