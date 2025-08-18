require "rails_helper"

RSpec.describe "Providers::Accreditations", type: :request do
  let(:provider) { create(:provider, :accredited) }

  describe "GET /providers/:provider_id/accreditations" do
    context "when not authenticated" do
      it "redirects to sign in" do
        get provider_accreditations_path(provider)
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to("/sign-in")
      end
    end
  end
end
