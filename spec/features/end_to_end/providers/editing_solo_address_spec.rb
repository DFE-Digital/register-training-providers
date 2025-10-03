require "rails_helper"

RSpec.describe "Editing solo address", type: :feature do
  before do
    given_i_am_an_authenticated_user
  end

  context "with valid data" do
    let(:provider) { create(:provider, :hei) }
    let!(:address) do
      create(:address,
             provider: provider,
             address_line_1: "Original Street",
             address_line_2: "Original Building",
             address_line_3: "Original Floor",
             town_or_city: "Original City",
             county: "Original County",
             postcode: "SW1A 1AA")
    end

    scenario "edits address for provider" do
      visit provider_addresses_path(provider)

      expect(page).to have_content("Original Street")
      expect(page).to have_content("Original City")

      click_link "Change", match: :first

      expect(page).to have_content("Edit address - #{provider.operating_name}")
      expect(page).to have_field("Address line 1", with: "Original Street")
      expect(page).to have_field("Address line 2 (optional)", with: "Original Building")
      expect(page).to have_field("Address line 3 (optional)", with: "Original Floor")
      expect(page).to have_field("Town or city", with: "Original City")
      expect(page).to have_field("County (optional)", with: "Original County")
      expect(page).to have_field("Postcode", with: "SW1A 1AA")

      expect(TemporaryRecord.count).to eq(0)

      fill_in "Address line 1", with: "Updated Test Street"
      fill_in "Address line 2 (optional)", with: "Updated Building"
      fill_in "Address line 3 (optional)", with: "Updated Floor"
      fill_in "Town or city", with: "Updated City"
      fill_in "County (optional)", with: "Updated County"
      fill_in "Postcode", with: "M1 1AA"

      click_button "Continue"

      expect(TemporaryRecord.count).to eq(1)
      expect(page).to have_content("Check your answers")
      expect(page).to have_content("Updated Test Street")
      expect(page).to have_content("Updated Building")
      expect(page).to have_content("Updated Floor")
      expect(page).to have_content("Updated City")
      expect(page).to have_content("Updated County")
      expect(page).to have_content("M1 1AA")

      click_button "Save address"

      expect(TemporaryRecord.count).to eq(0)
      expect(page).to have_content("Address updated")
      expect(page).to have_content("Updated Test Street")

      address.reload
      expect(address.address_line_1).to eq("Updated Test Street")
      expect(address.address_line_2).to eq("Updated Building")
      expect(address.address_line_3).to eq("Updated Floor")
      expect(address.town_or_city).to eq("Updated City")
      expect(address.county).to eq("Updated County")
      expect(address.postcode).to eq("M1 1AA")
    end

    scenario "edits address with minimal required fields only" do
      visit edit_provider_address_path(address, provider_id: provider.id)

      fill_in "Address line 1", with: "Minimal Updated Road"
      fill_in "Address line 2 (optional)", with: ""
      fill_in "Address line 3 (optional)", with: ""
      fill_in "Town or city", with: "Minimal Updated Town"
      fill_in "County (optional)", with: ""
      fill_in "Postcode", with: "B1 1AA"

      click_button "Continue"

      expect(page).to have_content("Check your answers")
      expect(page).to have_content("Minimal Updated Road")
      expect(page).to have_content("Minimal Updated Town")
      expect(page).to have_content("B1 1AA")

      click_button "Save address"

      expect(page).to have_content("Address updated")
      expect(provider.addresses.count).to eq(1)

      address.reload
      expect(address.address_line_1).to eq("Minimal Updated Road")
      expect(address.address_line_2).to be_blank
      expect(address.address_line_3).to be_blank
      expect(address.town_or_city).to eq("Minimal Updated Town")
      expect(address.county).to be_blank
      expect(address.postcode).to eq("B1 1AA")
    end
  end

  context "with invalid data" do
    let(:provider) { create(:provider, :hei) }
    let!(:address) { create(:address, provider:) }

    scenario "missing required fields shows errors" do
      visit edit_provider_address_path(address, provider_id: provider.id)

      fill_in "Address line 1", with: ""
      fill_in "Town or city", with: ""
      fill_in "Postcode", with: ""

      click_button "Continue"

      expect(page).to have_error_summary("Enter address line 1, typically the building and street", "Enter town or city", "Enter postcode")
      expect(TemporaryRecord.count).to eq(0)
    end

    scenario "invalid postcode shows error" do
      visit edit_provider_address_path(address, provider_id: provider.id)

      fill_in "Postcode", with: "INVALID"

      click_button "Continue"

      expect(page).to have_error_summary("Enter a full UK postcode")
      expect(TemporaryRecord.count).to eq(0)
    end
  end

  context "check answers flow" do
    let(:provider) { create(:provider, :hei) }
    let!(:address) { create(:address, provider: provider, address_line_1: "Original Street") }

    scenario "can change values from check page and resubmit" do
      visit edit_provider_address_path(address, provider_id: provider.id)

      fill_in "Address line 1", with: "First Update Street"
      fill_in "Town or city", with: "First Update City"

      click_button "Continue"

      expect(page).to have_content("Check your answers")
      expect(page).to have_content("First Update Street")
      expect(page).to have_content("First Update City")

      click_link "Change", match: :first

      expect(page).to have_field("Address line 1", with: "First Update Street")
      expect(page).to have_field("Town or city", with: "First Update City")

      fill_in "Address line 1", with: "Final Update Street"

      click_button "Continue"

      expect(page).to have_content("Final Update Street")
      expect(page).to have_content("First Update City")

      click_button "Save address"

      expect(page).to have_content("Address updated")
      expect(page).to have_content("Final Update Street")
    end

    scenario "can cancel and return to addresses" do
      visit edit_provider_address_path(address, provider_id: provider.id)

      fill_in "Address line 1", with: "Cancelled Street"

      click_link "Cancel"

      expect(page).to have_current_path(provider_addresses_path(provider))
      expect(TemporaryRecord.count).to eq(0)

      address.reload
      expect(address.address_line_1).to eq("Original Street")
    end
  end
end
