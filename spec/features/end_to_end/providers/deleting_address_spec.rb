require "rails_helper"

RSpec.describe "Deleting address", type: :feature do
  before do
    given_i_am_an_authenticated_user
  end

  context "with an existing address" do
    let(:provider) { create(:provider, :hei) }
    let!(:address) do
      create(:address,
             provider: provider,
             address_line_1: "123 Test Street",
             address_line_2: "Test Building",
             address_line_3: "Test Floor",
             town_or_city: "Test City",
             county: "Test County",
             postcode: "SW1A 1AA")
    end

    scenario "deletes address for provider" do
      visit provider_addresses_path(provider)

      expect(page).to have_content("123 Test Street")
      expect(page).to have_content("Test City, SW1A 1AA")
      expect(provider.addresses.kept.count).to eq(1)

      click_link "Delete", match: :first

      expect(page).to have_content("Confirm you want to delete #{provider.operating_name}’s address")
      expect(page).to have_content("Delete address")

      expect(page).to have_content("123 Test Street")
      expect(page).to have_content("Test Building")
      expect(page).to have_content("Test Floor")
      expect(page).to have_content("Test City")
      expect(page).to have_content("Test County")
      expect(page).to have_content("SW1A 1AA")

      expect(page).to have_content("Deleting an address is permanent – you cannot undo it.")

      expect(page).to have_link("Cancel", href: provider_addresses_path(provider))

      click_button "Delete address"

      expect(current_path).to eq(provider_addresses_path(provider))

      expect(page).to have_content("Address deleted")

      expect(page).not_to have_content("123 Test Street")
      expect(page).to have_content("There are no addresses for #{provider.operating_name}")

      expect(provider.addresses.kept.count).to eq(0)
      expect(provider.addresses.count).to eq(1)
      expect(address.reload.discarded?).to be true
    end

    scenario "cancels deletion and returns to addresses" do
      visit provider_addresses_path(provider)

      click_link "Delete", match: :first

      expect(page).to have_content("Confirm you want to delete #{provider.operating_name}’s address")

      click_link "Cancel"

      expect(current_path).to eq(provider_addresses_path(provider))

      expect(page).to have_content("123 Test Street")
      expect(page).to have_content("Test City, SW1A 1AA")
      expect(provider.addresses.kept.count).to eq(1)
      expect(address.reload.discarded?).to be false
    end
  end

  context "with multiple addresses" do
    let(:provider) { create(:provider, :hei) }
    let!(:address1) do
      create(:address,
             provider: provider,
             address_line_1: "First Address Street",
             town_or_city: "First City",
             postcode: "SW1A 1AA")
    end
    let!(:address2) do
      create(:address,
             provider: provider,
             address_line_1: "Second Address Street",
             town_or_city: "Second City",
             postcode: "M1 1AA")
    end

    scenario "deletes one address while keeping others" do
      visit provider_addresses_path(provider)

      expect(page).to have_content("First Address Street")
      expect(page).to have_content("Second Address Street")
      expect(provider.addresses.kept.count).to eq(2)

      within(".govuk-summary-card", text: "First City, SW1A 1AA") do
        click_link "Delete"
      end

      expect(page).to have_content("Confirm you want to delete #{provider.operating_name}’s address")
      expect(page).to have_content("First Address Street")

      click_button "Delete address"

      expect(current_path).to eq(provider_addresses_path(provider))

      expect(page).to have_content("Address deleted")

      expect(page).not_to have_content("First Address Street")
      expect(page).to have_content("Second Address Street")
      expect(page).to have_content("Addresses (1)")

      expect(provider.addresses.kept.count).to eq(1)
      expect(provider.addresses.count).to eq(2)
      expect(address1.reload.discarded?).to be true
      expect(address2.reload.discarded?).to be false
    end
  end
end
