require "rails_helper"

RSpec.describe "Provider partnership step role access", type: :request do
  include DfESignInUserHelper

  let(:accredited_provider) { create(:provider, :accredited) }

  describe "a journey step" do
    it "denies RO" do
      sign_in_as(create(:user, :ro))

      get provider_partnership_step_path(accredited_provider, step: "start-date")
      expect(response).to have_http_status(:forbidden)

      post provider_partnership_step_path(accredited_provider, step: "start-date"),
           params: { start_date: { start_today: "true" } }
      expect(response).to have_http_status(:forbidden)
    end

    it "denies BAT on an accredited provider" do
      sign_in_as(create(:user, :bat))

      get provider_partnership_step_path(accredited_provider, step: "start-date")
      expect(response).to have_http_status(:forbidden)
    end

    it "permits MR, who is redirected into the journey" do
      sign_in_as(create(:user, :mr))

      get provider_partnership_step_path(accredited_provider, step: "start-date")

      expect(response).to have_http_status(:redirect)
    end

    it "permits MR on the academic years step" do
      sign_in_as(create(:user, :mr))

      get provider_partnership_step_path(accredited_provider, step: "academic-years")

      expect(response).to have_http_status(:redirect)
    end
  end
end
