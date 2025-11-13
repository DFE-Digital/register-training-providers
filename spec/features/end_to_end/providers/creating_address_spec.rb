require "rails_helper"

RSpec.describe "Creating address", type: :feature do
  before do
    given_i_am_an_authenticated_user
  end

  context "with valid data" do
    let(:provider) { create(:provider, :hei) }

    scenario "creates address for provider" do
      visit provider_addresses_path(provider)

      expect(page).to have_content("There are no addresses for #{provider.operating_name}")

      within(".govuk-button-group") do
        click_link "Add address"
      end

      expect(page).to have_content(provider.operating_name)
      expect(page).to have_content("Address")

      fill_in "Address line 1", with: "123 Test Street"
      fill_in "Address line 2 (optional)", with: "Test Building"
      fill_in "Address line 3 (optional)", with: "Test Floor"
      fill_in "Town or city", with: "Test City"
      fill_in "County (optional)", with: "Test County"
      fill_in "Postcode", with: "SW1A 1AA"

      click_button "Continue"

      expect(page).to have_content("Check your answers")
      expect(page).to have_content("123 Test Street")
      expect(page).to have_content("Test Building")
      expect(page).to have_content("Test Floor")
      expect(page).to have_content("Test City")
      expect(page).to have_content("Test County")
      expect(page).to have_content("SW1A 1AA")

      click_button "Save address"

      expect(page).to have_content("Address added")
      expect(page).to have_content("123 Test Street")

      provider.reload
      expect(provider.addresses.count).to eq(1)

      address = provider.addresses.first
      expect(address.address_line_1).to eq("123 Test Street")
      expect(address.address_line_2).to eq("Test Building")
      expect(address.address_line_3).to eq("Test Floor")
      expect(address.town_or_city).to eq("Test City")
      expect(address.county).to eq("Test County")
      expect(address.postcode).to eq("SW1A 1AA")
    end

    scenario "creates minimal address with only required fields" do
      visit new_provider_address_path(provider_id: provider.id)

      fill_in "Address line 1", with: "456 Minimal Road"
      fill_in "Town or city", with: "Minimal Town"
      fill_in "Postcode", with: "M1 1AA"

      click_button "Continue"

      expect(page).to have_content("Check your answers")
      expect(page).to have_content("456 Minimal Road")
      expect(page).to have_content("Minimal Town")
      expect(page).to have_content("M1 1AA")

      click_button "Save address"

      expect(page).to have_content("Address added")
      expect(provider.addresses.count).to eq(1)

      address = provider.addresses.first
      expect(address.address_line_1).to eq("456 Minimal Road")
      expect(address.address_line_2).to be_blank
      expect(address.address_line_3).to be_blank
      expect(address.town_or_city).to eq("Minimal Town")
      expect(address.county).to be_blank
      expect(address.postcode).to eq("M1 1AA")
    end
  end

  context "cancellation flow" do
    let(:provider) { create(:provider, :hei) }

    scenario "can cancel and return to addresses" do
      visit new_provider_address_path(provider_id: provider.id)

      fill_in "Address line 1", with: "Test Street"

      click_link "Cancel"

      expect(page).to have_current_path(provider_addresses_path(provider))
    end
  end
end
