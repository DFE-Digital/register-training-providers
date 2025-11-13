require "rails_helper"

RSpec.feature "Provider Creation - Back Button Navigation" do
  let(:address_api_response) do
    [
      {
        address_line_1: "10 Downing Street",
        address_line_2: nil,
        town_or_city: "London",
        county: nil,
        postcode: "SW1A 1AA",
        latitude: 51.503396,
        longitude: -0.127764
      },
      {
        address_line_1: "11 Downing Street",
        address_line_2: nil,
        town_or_city: "London",
        county: nil,
        postcode: "SW1A 1AA",
        latitude: 51.503396,
        longitude: -0.127764
      }
    ]
  end

  before do
    # Stub Ordnance Survey API for address search tests
    allow(OrdnanceSurvey::AddressLookupService).to receive(:call).and_return(address_api_response)
    allow(Addresses::GeocodeService).to receive(:call).and_return({ latitude: 51.503396, longitude: -0.127764 })
  end

  context "Normal flow (first time through journey)" do
    scenario "Unaccredited provider - back buttons go to previous step in journey" do
      given_i_am_an_authenticated_user
      when_i_start_creating_a_provider
      and_i_answer_the_accreditation_question_as("No")

      # Now on Type page - select type but don't continue yet to test back button
      then_i_should_be_on_the_type_page
      choose("Higher education institution (HEI)")
      when_i_click_on("Continue")

      # Test back button from Details page
      then_i_should_be_on_the_details_page
      when_i_click_the_back_link
      then_i_should_be_on_the_type_page
      and_my_provider_type_should_be_selected("Higher education institution (HEI)")

      # Test back to onboarding
      when_i_click_the_back_link
      then_i_should_be_on_the_onboarding_page
      and_my_accreditation_answer_should_be_selected("No")

      # Go forward through journey again
      when_i_click_on("Continue")
      then_i_should_be_on_the_type_page
      and_my_provider_type_should_be_selected("Higher education institution (HEI)")

      # Continue to details
      when_i_click_on("Continue")
      and_i_fill_in_provider_details

      # Now on address page - test back button
      when_i_click_the_back_link
      then_i_should_be_on_the_details_page
      and_my_provider_details_should_be_filled

      # Go forward to address
      when_i_click_on("Continue")
      and_i_fill_in_manual_address

      # Now on check page - test back button
      when_i_click_the_back_link
      then_i_should_be_on_the_address_page
      and_my_address_should_be_filled

      # Complete the journey
      when_i_click_on("Continue")
      then_i_should_be_on_the_check_page
      when_i_click_on("Save provider")
      then_i_should_see_success_message
    end

    scenario "Accredited provider - back from address goes to accreditation" do
      given_i_am_an_authenticated_user
      when_i_start_creating_a_provider
      and_i_answer_the_accreditation_question_as("Yes")
      and_i_select_provider_type("School-centred initial teacher training (SCITT)")
      and_i_fill_in_provider_details
      then_i_should_be_on_the_accreditation_page
      and_i_fill_in_accreditation_details

      # Test back from Address to Accreditation
      when_i_click_the_back_link
      then_i_should_be_on_the_accreditation_page
      and_my_accreditation_details_should_be_filled

      # Go forward
      when_i_click_on("Continue")
      and_i_fill_in_manual_address

      # Back from Check to Address
      when_i_click_the_back_link
      then_i_should_be_on_the_address_page

      # Complete
      when_i_click_on("Continue")
      then_i_should_be_on_the_check_page
      when_i_click_on("Save provider")
      then_i_should_see_success_message
    end

    scenario "Select page 'Manual entry instead' - back goes to select with results" do
      given_i_am_an_authenticated_user
      when_i_start_creating_a_provider
      and_i_complete_provider_details_as_unaccredited

      # Use address finder
      when_i_search_for_an_address
      then_i_should_see_address_results

      # Choose manual entry instead
      when_i_click_on("Enter address manually")
      then_i_should_be_on_the_manual_entry_page

      # Back should go to Select with results still there
      when_i_click_the_back_link
      then_i_should_be_on_the_select_page
      and_i_should_see_address_results

      # Can select an address and continue
      when_i_select_the_first_address
      when_i_click_on("Continue")
      then_i_should_be_on_the_check_page
    end
  end

  context "Change flow (from Check page with goto=confirm)" do
    scenario "Change provider type - back unwinds to check page" do
      given_i_am_an_authenticated_user
      and_i_have_completed_provider_creation_to_check_page

      # Click change on provider type
      click_on("Change", match: :first) # Use click_on directly to support options
      then_i_should_be_on_the_type_page
      expect(page.current_url).to include("goto=confirm")

      # Back should go to check, not onboarding
      when_i_click_the_back_link
      then_i_should_be_on_the_check_page
    end

    scenario "Change provider type - continue returns to check page" do
      given_i_am_an_authenticated_user
      and_i_have_completed_provider_creation_to_check_page

      # Click change on provider type
      click_on("Change", match: :first)
      then_i_should_be_on_the_type_page
      expect(page.current_url).to include("goto=confirm")

      # Change selection and continue should return to check
      choose "School"
      when_i_click_on("Continue")
      then_i_should_be_on_the_check_page
    end

    scenario "Change provider details - continue returns to check page" do
      given_i_am_an_authenticated_user
      and_i_have_completed_provider_creation_to_check_page

      # Click change on operating name (a provider detail field)
      when_i_click_on_change_provider_details_link
      then_i_should_be_on_the_details_page
      expect(page.current_url).to include("goto=confirm")

      # Change operating name and continue should return to check
      fill_in "Operating name", with: "New Operating Name"
      when_i_click_on("Continue")
      then_i_should_be_on_the_check_page
      expect(page).to have_content("New Operating Name")
    end

    scenario "Change address with search results - back unwinds through select to check" do
      given_i_am_an_authenticated_user
      and_i_have_completed_provider_creation_with_address_search

      # Click change on address
      when_i_click_on_change_address_link
      then_i_should_be_on_the_select_page
      expect(page.current_url).to include("goto=confirm")

      # Back should go to check
      when_i_click_the_back_link
      then_i_should_be_on_the_check_page
    end

    scenario "Change address - search again - back unwinds to select then check" do
      given_i_am_an_authenticated_user
      and_i_have_completed_provider_creation_with_address_search

      # Click change on address
      when_i_click_on_change_address_link
      then_i_should_be_on_the_select_page

      # Click "Change your search"
      when_i_click_on("Change your search")
      then_i_should_be_on_the_find_page
      and_my_original_search_should_be_filled

      # Back should go to Select (not Check)
      when_i_click_the_back_link
      then_i_should_be_on_the_select_page
      and_i_should_see_address_results

      # Back again should go to Check
      when_i_click_the_back_link
      then_i_should_be_on_the_check_page
    end

    scenario "Change address - manual entry instead - back goes directly to check" do
      given_i_am_an_authenticated_user
      and_i_have_completed_provider_creation_with_address_search

      # Click change on address
      when_i_click_on_change_address_link
      then_i_should_be_on_the_select_page

      # Choose manual entry instead
      when_i_click_on("Enter address manually")
      then_i_should_be_on_the_manual_entry_page

      # Back should go directly to Check (user cancels the address change)
      when_i_click_the_back_link
      then_i_should_be_on_the_check_page
    end

    scenario "Change address (manual entry only) - back goes to check" do
      given_i_am_an_authenticated_user
      and_i_have_completed_provider_creation_with_manual_address

      # Click change on address (should go to manual entry, no search results)
      when_i_click_on_change_address_link
      then_i_should_be_on_the_manual_entry_page

      # Back should go directly to Check (no select page to unwind through)
      when_i_click_the_back_link
      then_i_should_be_on_the_check_page
    end
  end

  def when_i_start_creating_a_provider
    visit providers_path
    click_on("Add provider")
  end

  def and_i_answer_the_accreditation_question_as(answer)
    @accreditation_answer = answer
    @accreditation_status = answer == "Yes" ? "accredited" : "unaccredited"
    choose(answer)
    click_on("Continue")
  end

  def and_i_select_provider_type(type)
    @provider_type = type
    choose(type)
    click_on("Continue")
  end

  def and_i_fill_in_provider_details
    # Build provider with correct accreditation status and provider type based on earlier choices
    trait = @accreditation_status == "accredited" ? :accredited : :unaccredited

    # Map display name to factory symbol
    provider_type_map = {
      "Higher education institution (HEI)" => :hei,
      "School-centred initial teacher training (SCITT)" => :scitt,
      "School" => :school
    }
    provider_type_symbol = provider_type_map[@provider_type] || :hei

    @provider = build(:provider, trait, provider_type: provider_type_symbol)
    fill_in "Operating name", with: @provider.operating_name
    fill_in "Legal name (optional)", with: @provider.legal_name
    fill_in "UK provider reference number (UKPRN)", with: @provider.ukprn
    fill_in "Unique reference number (URN)", with: @provider.urn if @provider.urn.present?
    fill_in "Provider code", with: @provider.code

    click_on("Continue")
  end

  def and_i_fill_in_accreditation_details
    # Accreditation number format depends on provider type:
    # - HEI: starts with 1 (e.g. "1234")
    # - SCITT/School: starts with 5 (e.g. "5678")
    @accreditation_number = @provider_type.include?("HEI") ? "1234" : "5678"
    fill_in "Accredited provider number", with: @accreditation_number
    fill_in "accreditation_start_date_3i", with: "1"
    fill_in "accreditation_start_date_2i", with: "1"
    fill_in "accreditation_start_date_1i", with: Date.current.year.to_s
    click_on("Continue")
  end

  def and_i_fill_in_manual_address
    # Need to visit with skip_finder param to go directly to manual entry
    visit providers_setup_addresses_address_path(skip_finder: "true")

    @address = build(:address)
    fill_in "Address line 1", with: @address.address_line_1
    fill_in "Town or city", with: @address.town_or_city
    fill_in "Postcode", with: @address.postcode
    click_on("Continue")
  end

  def when_i_click_the_back_link
    click_on("Back")
  end

  def then_i_should_be_on_the_onboarding_page
    expect(page).to have_current_path("/providers/new", ignore_query: true)
  end

  def then_i_should_be_on_the_type_page
    expect(page).to have_current_path("/providers/new/type", ignore_query: true)
  end

  def then_i_should_be_on_the_details_page
    expect(page).to have_current_path("/providers/new/details", ignore_query: true)
  end

  def then_i_should_be_on_the_accreditation_page
    expect(page).to have_current_path("/providers/new/accreditation", ignore_query: true)
  end

  def then_i_should_be_on_the_address_page
    expect(page).to have_current_path("/providers/new/addresses", ignore_query: true)
  end

  def then_i_should_be_on_the_check_page
    expect(page).to have_current_path("/providers/check/new", ignore_query: true)
  end

  def and_my_accreditation_answer_should_be_selected(answer)
    # The form should have persisted the selection
    # Check by finding any checked radio button with the correct value
    status_value = answer == "Yes" ? "accredited" : "unaccredited"
    expect(page).to have_checked_field("provider[accreditation_status]", with: status_value)
  end

  def and_my_provider_type_should_be_selected(type)
    expect(find_field(type, checked: true)).to be_present
  end

  def and_my_provider_details_should_be_filled
    expect(find_field("Operating name").value).to eq(@provider.operating_name)
    expect(find_field("UK provider reference number (UKPRN)").value).to eq(@provider.ukprn)
    expect(find_field("Provider code").value).to eq(@provider.code)
  end

  def and_my_accreditation_details_should_be_filled
    expect(find_field("Accredited provider number").value).to eq(@accreditation_number)
  end

  def and_my_address_should_be_filled
    expect(find_field("Address line 1").value).to eq(@address.address_line_1)
    expect(find_field("Town or city").value).to eq(@address.town_or_city)
    expect(find_field("Postcode").value).to eq(@address.postcode)
  end

  def then_i_should_see_success_message
    expect(page).to have_notification_banner("Success", "Provider added")
  end

  # Helpers for address search/select flow
  def and_i_complete_provider_details_as_unaccredited
    and_i_answer_the_accreditation_question_as("No")
    and_i_select_provider_type("Higher education institution (HEI)")
    and_i_fill_in_provider_details
  end

  def when_i_search_for_an_address
    @search_postcode = "SW1A 1AA"
    @search_building = "10"
    fill_in "Postcode", with: @search_postcode
    fill_in "Building number or name (optional)", with: @search_building
    click_on("Find address")
  end

  def then_i_should_see_address_results
    expect(page).to have_content("addresses found")
    expect(page).to have_css('input[type="radio"]')
  end

  alias_method :and_i_should_see_address_results, :then_i_should_see_address_results

  def when_i_select_the_first_address
    first('input[type="radio"]').choose
  end

  def then_i_should_be_on_the_select_page
    expect(page).to have_current_path(/\/providers\/.*\/addresses\/select/)
  end

  def then_i_should_be_on_the_find_page
    expect(page).to have_current_path(/\/providers\/.*\/addresses\/find/)
  end

  def then_i_should_be_on_the_manual_entry_page
    expect(page).to have_current_path(/\/providers\/.*\/addresses$/, ignore_query: true)
  end

  def and_my_original_search_should_be_filled
    expect(find_field("Postcode").value).to eq(@search_postcode)
    expect(find_field("Building number or name (optional)").value).to eq(@search_building)
  end

  # Helpers for "Change" flow from Check page
  def and_i_have_completed_provider_creation_to_check_page
    when_i_start_creating_a_provider
    and_i_complete_provider_details_as_unaccredited
    and_i_fill_in_manual_address
    then_i_should_be_on_the_check_page
  end

  def and_i_have_completed_provider_creation_with_address_search
    when_i_start_creating_a_provider
    and_i_complete_provider_details_as_unaccredited
    when_i_search_for_an_address
    when_i_select_the_first_address
    click_on("Continue")
    then_i_should_be_on_the_check_page
  end

  def and_i_have_completed_provider_creation_with_manual_address
    when_i_start_creating_a_provider
    and_i_complete_provider_details_as_unaccredited
    and_i_fill_in_manual_address
    then_i_should_be_on_the_check_page
  end

  def when_i_click_on_change_address_link
    # Find the "Change" link in the address section
    # Look for the Address heading and click the Change link after it
    address_heading = find("h2", text: "Address")
    address_section = address_heading.find(:xpath, "./following-sibling::*[1]")
    within(address_section) do
      click_on("Change", match: :first)
    end
  end

  def when_i_click_on_change_provider_details_link
    # Find the "Change" link specifically for operating name (first provider detail field)
    within find("dl.govuk-summary-list", match: :first) do
      # Find the row with "Operating name" and click its change link
      operating_name_row = find("dt", text: "Operating name").ancestor("div.govuk-summary-list__row")
      within(operating_name_row) do
        click_on("Change")
      end
    end
  end
end
