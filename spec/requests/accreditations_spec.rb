require "rails_helper"

RSpec.describe "Accreditations", type: :request do
  let(:provider) { create(:provider, :accredited) }

  describe "GET /accreditations/new" do
    context "when not authenticated" do
      it "redirects to sign in" do
        get new_accreditation_path(provider_id: provider.id)
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to("/sign-in")
      end
    end
  end
end
