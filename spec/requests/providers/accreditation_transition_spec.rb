require "rails_helper"

RSpec.describe "Accreditation transition", type: :request do
  include DfESignInUserHelper

  let(:provider) { create(:provider, :accredited) }
  let(:accreditation) { provider.current_accreditation }

  it "moves edit rights from MR to BAT when the last accreditation is removed" do
    sign_in_as(create(:user, :mr))

    delete accreditation_delete_path(accreditation, provider_id: provider.id)

    expect(provider.reload).to be_unaccredited

    get provider_change_step_path(provider_id: provider.id, field: "operating_name", step: "effective-date")
    expect(response).to have_http_status(:forbidden)

    sign_in_as(create(:user, :bat))

    get provider_change_step_path(provider_id: provider.id, field: "operating_name", step: "effective-date")
    expect(response).to have_http_status(:ok)
  end
end
