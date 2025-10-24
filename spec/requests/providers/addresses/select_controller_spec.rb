require "rails_helper"

RSpec.describe Providers::Addresses::SelectController, type: :request do
  let(:provider) { create(:provider) }
  let(:user) { create(:user) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe "GET /providers/:provider_id/addresses/select/new" do
    context "when search results exist" do
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
        search_results_form = Addresses::SearchResultsForm.new
        search_results_form.results_array = addresses
        search_results_form.save_as_temporary!(
          created_by: user,
          purpose: :"address_search_results_#{provider.id}"
        )
      end

      it "renders the select form" do
        get new_provider_select_path(provider_id: provider.id)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Select address")
      end

      it "displays the search results" do
        get new_provider_select_path(provider_id: provider.id)

        expect(response.body).to include("10 Downing Street")
      end
    end

    context "when no search results exist" do
      it "redirects to find page" do
        get new_provider_select_path(provider_id: provider.id)

        expect(response).to redirect_to(find_provider_addresses_path(provider_id: provider.id))
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

    before do
      search_results_form = Addresses::SearchResultsForm.new
      search_results_form.results_array = addresses
      search_results_form.save_as_temporary!(
        created_by: user,
        purpose: :"address_search_results_#{provider.id}"
      )
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
        post provider_select_path(provider_id: provider.id), params: params

        expect(response).to redirect_to(new_provider_address_confirm_path(provider_id: provider.id))
      end

      it "saves the address form as temporary" do
        post provider_select_path(provider_id: provider.id), params: params

        address_form = user.load_temporary(AddressForm, purpose: :create_address)
        expect(address_form.address_line_1).to eq("10 Downing Street")
        expect(address_form.town_or_city).to eq("London")
        expect(address_form.postcode).to eq("SW1A 2AA")
      end

      it "clears temporary find and search results forms" do
        find_form = Addresses::FindForm.new(postcode: "SW1A 2AA")
        find_form.save_as_temporary!(created_by: user, purpose: :"find_address_#{provider.id}")

        post provider_select_path(provider_id: provider.id), params: params

        expect(user.load_temporary(Addresses::FindForm, purpose: :"find_address_#{provider.id}")).to be_nil
        expect(user.load_temporary(Addresses::SearchResultsForm, purpose: :"address_search_results_#{provider.id}")).to be_nil
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
        post provider_select_path(provider_id: provider.id), params: params

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
        post provider_select_path(provider_id: provider.id), params: params

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Please select an address")
      end
    end
  end
end

