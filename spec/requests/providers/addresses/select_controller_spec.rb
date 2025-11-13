require "rails_helper"

RSpec.describe Providers::Addresses::SelectController, type: :request do
  let(:provider) { create(:provider) }
  let(:user) { create(:user) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe "GET /providers/:provider_id/addresses/select/new" do
    context "when search results exist in session" do
      let(:addresses) do
        [
          {
            "address_line_1" => "10 Downing Street",
            "town_or_city" => "London",
            "postcode" => "SW1A 2AA"
          }
        ]
      end

      before do
        # Store search results in session (new approach)
        get new_provider_select_path(provider_id: provider.id), session: {
          address_creation: {
            search: {
              postcode: "SW1A 2AA",
              building_name_or_number: nil,
              results: addresses
            }
          }
        }
      end

      it "renders the select form" do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Select address")
      end

      it "displays the search results" do
        expect(response.body).to include("10 Downing Street")
      end
    end

    context "when no search results exist" do
      it "redirects to find page" do
        get new_provider_select_path(provider_id: provider.id)

        expect(response).to redirect_to(provider_new_find_path(provider))
      end
    end
  end

  describe "POST /providers/:provider_id/addresses/select" do
    let(:addresses) do
      [
        {
          "address_line_1" => "10 Downing Street",
          "town_or_city" => "London",
          "postcode" => "SW1A 2AA"
        }
      ]
    end

    let(:session_data) do
      {
        address_creation: {
          search: {
            postcode: "SW1A 2AA",
            building_name_or_number: nil,
            results: addresses
          }
        }
      }
    end

    context "with valid selection" do
      let(:params) do
        {
          select: {
            selected_address_index: "0"
          }
        }
      end

      it "redirects to check answers page" do
        post provider_select_path(provider_id: provider.id), params: params, session: session_data

        expect(response).to redirect_to(provider_new_address_confirm_path(provider_id: provider.id))
      end

      it "stores the selected address in session" do
        post provider_select_path(provider_id: provider.id), params: params, session: session_data

        # Address should be stored in session
        expect(session[:address_creation][:address]).to be_present
        expect(session[:address_creation][:address]["address_line_1"]).to eq("10 Downing Street")
        expect(session[:address_creation][:address]["town_or_city"]).to eq("London")
        expect(session[:address_creation][:address]["postcode"]).to eq("SW1A 2AA")
      end
    end

    context "with invalid selection index" do
      let(:params) do
        {
          select: {
            selected_address_index: "99"
          }
        }
      end

      it "re-renders with error" do
        post provider_select_path(provider_id: provider.id), params: params, session: session_data

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Please select an address")
      end
    end

    context "with negative selection index" do
      let(:params) do
        {
          select: {
            selected_address_index: "-1"
          }
        }
      end

      it "re-renders with error" do
        post provider_select_path(provider_id: provider.id), params: params, session: session_data

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Please select an address")
      end
    end

    context "when no search results exist in session" do
      it "redirects to find page" do
        post provider_select_path(provider_id: provider.id), params: {
          select: { selected_address_index: "0" }
        }

        expect(response).to redirect_to(provider_new_find_path(provider))
        expect(flash[:alert]).to eq("Please search for an address first")
      end
    end
  end
end
