require "rails_helper"

RSpec.describe "Provider partnership find", type: :request do
  include DfESignInUserHelper

  let(:user) { create(:user) }

  before do
    user_exists_in_dfe_sign_in(user:)
    get "/auth/dfe/callback"
  end

  after { OmniAuth.config.mock_auth.clear }

  context "when the provider is accredited" do
    let(:accredited_provider) { create(:provider, :accredited, operating_name: "Accredited Provider") }
    let!(:unaccredited_scitt) { create(:provider, :scitt_without_accreditation, operating_name: "Unaccredited SCITT") }
    let!(:unaccredited_school) { create(:provider, :school, operating_name: "Unaccredited School") }
    let!(:accredited_school) { create(:provider, :school_with_accreditation, operating_name: "Accredited School") }

    it "offers unaccredited providers as eligible training partners" do
      get provider_new_partnership_find_path(accredited_provider)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Unaccredited SCITT")
      expect(response.body).to include("Unaccredited School")
      expect(response.body).not_to include("Accredited School")
    end
  end

  context "when the provider is unaccredited" do
    let(:unaccredited_provider) { create(:provider, :hei_without_accreditation, operating_name: "Unaccredited Provider") }
    let!(:accredited_school) { create(:provider, :school_with_accreditation, operating_name: "Accredited School") }
    let!(:accredited_hei) { create(:provider, :hei, operating_name: "Accredited HEI") }
    let!(:unaccredited_scitt) { create(:provider, :scitt_without_accreditation, operating_name: "Unaccredited SCITT") }

    it "offers accredited providers as eligible partners, including an accredited school" do
      get provider_new_partnership_find_path(unaccredited_provider)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Accredited School")
      expect(response.body).to include("Accredited HEI")
      expect(response.body).not_to include("Unaccredited SCITT")
    end
  end
end
