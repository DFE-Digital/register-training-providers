require "rails_helper"

RSpec.describe "Creating address with finder", type: :feature do
  let(:provider) { create(:provider, :hei) }
  let(:api_response) do
    [
      {
        address_line_1: "10 Downing Street",
        address_line_2: nil,
        town_or_city: "London",
        county: nil,
        postcode: "SW1A 2AA",
        latitude: 51.503396,
        longitude: -0.127764
      }
    ]
  end

  before do
    given_i_am_an_authenticated_user
    allow(OrdnanceSurvey::AddressLookupService).to receive(:call).and_return(api_response)
    allow(Addresses::GeocodeService).to receive(:call).and_return({ latitude: 51.503396, longitude: -0.127764 })
  end

  scenario "finding and selecting a single address" do
    visit provider_addresses_path(provider)

    expect(page).to have_content("There are no addresses for #{provider.operating_name}")

    within(".govuk-button-group") do
      click_link "Add address"
    end

    expect(page).to have_content("Find address")
    expect(page).to have_content(provider.operating_name)

    fill_in "Postcode", with: "SW1A 2AA"
    click_button "Find address"

    expect(page).to have_content("Confirm address")
    expect(page).to have_content("10 Downing Street")
    expect(page).to have_content("London")
    expect(page).to have_content("SW1A 2AA")

    click_button "Confirm address"

    expect(page).to have_content("Check your answers")
    expect(page).to have_content("10 Downing Street")
    expect(page).to have_content("London")
    expect(page).to have_content("SW1A 2AA")

    click_button "Save address"

    expect(page).to have_content("Address added")
    expect(provider.addresses.count).to eq(1)

    address = provider.addresses.first
    expect(address.address_line_1).to eq("10 Downing Street")
    expect(address.town_or_city).to eq("London")
    expect(address.postcode).to eq("SW1A 2AA")
    expect(address.latitude).to eq(51.503396)
    expect(address.longitude).to eq(-0.127764)
  end

  scenario "finding and selecting from multiple addresses" do
    multiple_addresses = [
      {
        address_line_1: "10 Downing Street",
        town_or_city: "London",
        postcode: "SW1A 2AA",
        latitude: 51.503396,
        longitude: -0.127764
      },
      {
        address_line_1: "11 Downing Street",
        town_or_city: "London",
        postcode: "SW1A 2AA",
        latitude: 51.503400,
        longitude: -0.127800
      }
    ]
    allow(OrdnanceSurvey::AddressLookupService).to receive(:call).and_return(multiple_addresses)

    visit new_provider_find_path(provider_id: provider.id)

    fill_in "Postcode", with: "SW1A 2AA"
    click_button "Find address"

    expect(page).to have_content("Select an address")
    expect(page).to have_content("2 addresses found")
    expect(page).to have_content("10 Downing Street, London, SW1A 2AA")
    expect(page).to have_content("11 Downing Street, London, SW1A 2AA")

    choose "11 Downing Street, London, SW1A 2AA"
    click_button "Continue"

    expect(page).to have_content("Check your answers")
    expect(page).to have_content("11 Downing Street")

    click_button "Save address"

    address = provider.addresses.first
    expect(address.address_line_1).to eq("11 Downing Street")
  end

  scenario "no addresses found, enter manually" do
    allow(OrdnanceSurvey::AddressLookupService).to receive(:call).and_return([])

    visit new_provider_find_path(provider_id: provider.id)

    fill_in "Postcode", with: "XX1 1XX"
    click_button "Find address"

    expect(page).to have_content("No addresses found")
    expect(page).to have_content("We could not find any addresses for the postcode you entered")

    click_link "Enter address manually"

    expect(page).to have_content("Address")
    fill_in "Address line 1", with: "Custom Address"
    fill_in "Town or city", with: "Custom Town"
    fill_in "Postcode", with: "XX1 1XX"

    click_button "Continue"

    expect(page).to have_content("Check your answers")
    expect(page).to have_content("Custom Address")

    click_button "Save address"

    address = provider.addresses.first
    expect(address.address_line_1).to eq("Custom Address")
    expect(address.town_or_city).to eq("Custom Town")
  end

  scenario "choosing to enter address manually from find page" do
    visit new_provider_find_path(provider_id: provider.id)

    click_link "Enter address manually"

    expect(page).to have_content("Address")
    expect(page).not_to have_content("Find address")

    fill_in "Address line 1", with: "Manual Address"
    fill_in "Town or city", with: "Manual Town"
    fill_in "Postcode", with: "M1 1AA"

    click_button "Continue"

    expect(page).to have_content("Check your answers")
    click_button "Save address"

    address = provider.addresses.first
    expect(address.address_line_1).to eq("Manual Address")
  end

  scenario "choosing to enter address manually from select page" do
    visit new_provider_find_path(provider_id: provider.id)

    fill_in "Postcode", with: "SW1A 2AA"
    click_button "Find address"

    expect(page).to have_content("Confirm address")

    click_link "Enter address manually"

    expect(page).to have_content("Address")

    fill_in "Address line 1", with: "Different Address"
    fill_in "Town or city", with: "Different Town"
    fill_in "Postcode", with: "D1 1AA"

    click_button "Continue"

    expect(page).to have_content("Check your answers")
    click_button "Save address"

    address = provider.addresses.first
    expect(address.address_line_1).to eq("Different Address")
  end

  scenario "using back button from manual entry returns to find page" do
    visit new_provider_address_path(provider_id: provider.id, skip_finder: true)

    click_link "Back"

    expect(page).to have_content("Find address")
  end

  scenario "searching with building name or number" do
    visit new_provider_find_path(provider_id: provider.id)

    fill_in "Postcode", with: "SW1A 2AA"
    fill_in "Building name or number (optional)", with: "10"
    click_button "Find address"

    expect(OrdnanceSurvey::AddressLookupService).to have_received(:call).with(
      postcode: "SW1A 2AA",
      building_name_or_number: "10"
    )

    expect(page).to have_content("Confirm address")
  end

  scenario "validation error on find form" do
    visit new_provider_find_path(provider_id: provider.id)

    fill_in "Postcode", with: "INVALID"
    click_button "Find address"

    expect(page).to have_content("Find address")
    expect(page).to have_content("There is a problem")
  end

  scenario "validation error on select form" do
    visit new_provider_find_path(provider_id: provider.id)

    fill_in "Postcode", with: "SW1A 2AA"
    click_button "Find address"

    # Simulate posting without selecting an address by directly posting
    page.driver.post(
      provider_select_path(provider_id: provider.id),
      { select: { selected_address_index: "-1" } }
    )

    visit current_path

    expect(page).to have_content("Please select an address")
  end
end

