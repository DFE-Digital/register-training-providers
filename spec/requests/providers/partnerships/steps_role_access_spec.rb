require "rails_helper"

RSpec.describe "Provider partnership step role access", type: :request do
  include DfESignInUserHelper

  let(:accredited_provider) { create(:provider, :accredited) }

  describe "dates step" do
    it "denies RO" do
      sign_in_as(create(:user, :ro))

      get provider_new_partnership_dates_path(accredited_provider)
      expect(response).to have_http_status(:forbidden)

      post provider_partnership_dates_path(accredited_provider),
           params: {
             partnerships_dates_form: {
               "start_date(3i)" => "1",
               "start_date(2i)" => "9",
               "start_date(1i)" => "2025",
               "end_date(3i)" => "1",
               "end_date(2i)" => "9",
               "end_date(1i)" => "2026",
             },
           }
      expect(response).to have_http_status(:forbidden)
    end

    it "denies BAT" do
      sign_in_as(create(:user, :bat))

      get provider_new_partnership_dates_path(accredited_provider)
      expect(response).to have_http_status(:forbidden)
    end

    it "permits MR" do
      sign_in_as(create(:user, :mr))

      get provider_new_partnership_dates_path(accredited_provider)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "academic years step" do
    it "denies RO" do
      sign_in_as(create(:user, :ro))

      get provider_new_partnership_academic_years_path(accredited_provider)
      expect(response).to have_http_status(:forbidden)

      post provider_partnership_academic_years_path(accredited_provider), params: { select: { academic_year_ids: [] } }
      expect(response).to have_http_status(:forbidden)
    end

    it "denies BAT" do
      sign_in_as(create(:user, :bat))

      get provider_new_partnership_academic_years_path(accredited_provider)
      expect(response).to have_http_status(:forbidden)
    end

    it "permits MR" do
      sign_in_as(create(:user, :mr))

      get provider_new_partnership_academic_years_path(accredited_provider)
      expect(response).to have_http_status(:ok)
    end
  end
end
