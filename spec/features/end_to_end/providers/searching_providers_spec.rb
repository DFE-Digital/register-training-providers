RSpec.feature "Search Training Providers" do
  scenario "User searches for a provider by name" do
    given_i_am_on_the_provider_list_page
    when_i_enter_a_name_with_at_least_one_character_in_the_search_field
    then_the_list_of_providers_should_be_filtered_to_show_providers_matching_the_name
  end
  scenario "User searches for a provider by code" do
    given_i_am_on_the_provider_list_page
    when_i_enter_a_valid_code_in_the_search_field
    then_the_list_of_providers_should_be_filtered_to_show_the_provider_with_that_code
  end
  scenario "User searches for a provider by UKPRN" do
    given_i_am_on_the_provider_list_page
    when_i_enter_a_valid_ukprn_in_the_search_field
    then_the_list_of_providers_should_be_filtered_to_show_the_provider_with_that_ukprn
  end
  scenario "User searches for a provider by URN" do
    given_i_am_on_the_provider_list_page
    when_i_enter_a_valid_urn_in_the_search_field
    then_the_list_of_providers_should_be_filtered_to_show_the_provider_with_that_urn
  end
  scenario "User clears the search" do
    given_i_am_on_the_provider_list_page
    and_i_have_performed_a_search
    when_i_click_the_clear_search_link
    then_the_search_field_should_be_cleared
    and_the_full_list_of_providers_should_be_displayed
  end
  scenario "No providers found" do
    given_there_are_no_providers_matching_the_search_criteria
    when_i_perform_a_search
    then_a_message_is_shown("There are no providers.")
  end

  def and_there_are_a_number_of_providers
    provider_1
    provider_2
    provider_3
    provider_4
  end

  def provider_1
    @provider_1 ||= create(:provider, operating_name: "Magic Academy", urn: "12345", code: "DC1", ukprn: "11111111")
  end

  def provider_2
    @provider_2 ||= create(:provider, operating_name: "Science College", urn: "67890", code: "DC2", ukprn: "22222222")
  end

  def provider_3
    @provider_3 ||= create(:provider, operating_name: "History Institute", urn: "54321", code: "DC3", ukprn: "33333333")
  end

  def provider_4
    @provider_4 ||= create(:provider, operating_name: "Fredrick University", urn: "44444", code: "DC4", ukprn: "44444444")
  end

  def given_i_am_on_the_provider_list_page
    given_i_am_an_authenticated_user
    and_there_are_a_number_of_providers
    visit providers_path
  end

  def when_i_enter_a_name_with_at_least_one_character_in_the_search_field
    fill_in "Search by provider name, code, UKPRN or URN", with: "Magic"
    click_button "Search"
  end

  def then_the_list_of_providers_should_be_filtered_to_show_providers_matching_the_name
    expect(page).to have_content("Magic Academy")
    expect(page).not_to have_content("Science College")
    expect(page).not_to have_content("History Institute")
    expect(page).not_to have_content("Fredrick University")
  end

  def when_i_enter_a_valid_code_in_the_search_field
    fill_in "Search by provider name, code, UKPRN or URN", with: @provider_4.code
    click_button "Search"
  end

  def when_i_enter_a_valid_ukprn_in_the_search_field
    fill_in "Search by provider name, code, UKPRN or URN", with: @provider_2.ukprn
    click_button "Search"
  end

  def then_the_list_of_providers_should_be_filtered_to_show_the_provider_with_that_code
    expect(page).to have_content(provider_4.operating_name)
    expect(page).not_to have_content(provider_1.operating_name)
    expect(page).not_to have_content(provider_3.operating_name)
    expect(page).not_to have_content(provider_2.operating_name)
  end

  def then_the_list_of_providers_should_be_filtered_to_show_the_provider_with_that_ukprn
    expect(page).to have_content(provider_2.operating_name)
    expect(page).not_to have_content(provider_1.operating_name)
    expect(page).not_to have_content(provider_3.operating_name)
    expect(page).not_to have_content(provider_4.operating_name)
  end

  def when_i_enter_a_valid_urn_in_the_search_field
    fill_in "Search by provider name, code, UKPRN or URN", with: provider_3.urn
    click_button "Search"
  end

  def then_the_list_of_providers_should_be_filtered_to_show_the_provider_with_that_urn
    expect(page).to have_content(provider_3.operating_name)
    expect(page).not_to have_content(provider_1.operating_name)
    expect(page).not_to have_content(provider_2.operating_name)
    expect(page).not_to have_content(provider_4.operating_name)
  end

  def when_i_search_for(term)
    fill_in "Search by provider name, code, UKPRN or URN", with: term
    click_button "Search"
  end

  def when_i_click_the_clear_search_link
    click_link "Clear search"
  end

  def then_the_search_field_should_be_cleared
    expect(find_field("Search by provider name, code, UKPRN or URN").value).to be_blank
  end

  def and_the_full_list_of_providers_should_be_displayed
    expect(page).to have_content(provider_1.operating_name)
    expect(page).to have_content(provider_2.operating_name)
    expect(page).to have_content(provider_3.operating_name)
    expect(page).to have_content(provider_4.operating_name)
  end

  def given_there_are_no_providers_matching_the_search_criteria
    given_i_am_an_authenticated_user
    create(:provider, operating_name: "TotallyDifferent", urn: "99999", ukprn: "44444444")
    visit providers_path
  end

  def when_i_perform_a_search
    fill_in "Search by provider name, code, UKPRN or URN", with: "NothingToSeeHere"
    click_button "Search"
  end

  def then_a_message_is_shown(message)
    expect(page).to have_content(message)
  end

  alias_method :and_i_have_performed_a_search, :when_i_perform_a_search
end
