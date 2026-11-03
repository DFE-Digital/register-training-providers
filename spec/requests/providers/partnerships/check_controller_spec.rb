require "rails_helper"

RSpec.describe "Provider partnership check your answers", type: :request do
  include DfESignInUserHelper

  let(:provider) { create(:provider) }

  before do
    sign_in_as(create(:user, :mr))
  end

  it "redirects to the finder when nothing has been staged" do
    get provider_new_partnership_confirm_path(provider)

    expect(response).to redirect_to(provider_new_partnership_find_path(provider))
  end

  it "redirects to the finder when creating without a staged partnership" do
    post provider_partnership_confirm_path(provider)

    expect(response).to redirect_to(provider_new_partnership_find_path(provider))
  end
end
