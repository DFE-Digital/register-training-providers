require "rails_helper"

RSpec.describe Providers::Addresses::FindController, type: :request do
  let(:provider) { create(:provider) }
  let(:user) { create(:user) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe "GET /providers/:provider_id/addresses/find/new" do
    it "renders the find form" do
      get new_provider_find_path(provider_id: provider.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Find address")
    end

    it "initializes the form with provider_id" do
      get new_provider_find_path(provider_id: provider.id)

      expect(assigns(:form).provider_id).to eq(provider.id)
    end
  end

  describe "POST /providers/:provider_id/addresses/find" do
    let(:valid_params) do
      {
        find: {
          postcode: "SW1A 2AA",
          building_name_or_number: "10"
        }
      }
    end

    let(:api_response) do
      [
        {
          address_line_1: "10 Downing Street",
          town_or_city: "London",
          postcode: "SW1A 2AA",
          latitude: 51.503396,
          longitude: -0.127764
        }
      ]
    end

    before do
      allow(OrdnanceSurvey::AddressLookupService).to receive(:call).and_return(api_response)
    end

    context "with valid postcode" do
      it "redirects to select page" do
        post provider_find_path(provider_id: provider.id), params: valid_params

        expect(response).to redirect_to(new_provider_select_path(provider_id: provider.id))
      end

      it "saves the search form as temporary" do
        expect do
          post provider_find_path(provider_id: provider.id), params: valid_params
        end.to change(TemporaryRecord, :count).by(2)
      end

      it "calls the address lookup service" do
        expect(OrdnanceSurvey::AddressLookupService).to receive(:call).with(
          postcode: "SW1A 2AA",
          building_name_or_number: "10"
        )

        post provider_find_path(provider_id: provider.id), params: valid_params
      end
    end

    context "with invalid postcode" do
      let(:invalid_params) do
        {
          find: {
            postcode: "INVALID"
          }
        }
      end

      it "re-renders the form with errors" do
        post provider_find_path(provider_id: provider.id), params: invalid_params

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Find address")
      end
    end

    context "with blank postcode" do
      let(:blank_params) do
        {
          find: {
            postcode: ""
          }
        }
      end

      it "re-renders the form with errors" do
        post provider_find_path(provider_id: provider.id), params: blank_params

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("can&#39;t be blank")
      end
    end
  end
end

