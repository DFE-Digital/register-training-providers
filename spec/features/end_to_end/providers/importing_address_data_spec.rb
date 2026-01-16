RSpec.feature "Importing addresses for training providers" do
  let(:api_response) do
    [
      {
        "address_line_1" => "10 Downing Street",
        "address_line_2" => nil,
        "town_or_city" => "London",
        "county" => nil,
        "postcode" => "SW1A 2AA",
        "latitude" => 51.503396,
        "longitude" => -0.127764
      }
    ]
  end

  before do
    allow(OrdnanceSurvey::AddressLookupService).to receive(:call).and_return(api_response)
  end

  scenario "user navigate to the provider with address issue" do
    given_i_am_on_the_providers_address_list_page
    and_i_should_see_providers_with_address_issues

    when_i_click_on_a_provider_with_address_issue
    then_i_should_be_taken_to_the_select_new_address_page
  end

  def given_i_am_on_the_providers_address_list_page
    given_i_am_an_authenticated_user
    and_there_are_a_provider_with_addresses_issues
    and_there_are_a_provider_without_addresses_issues
    visit providers_addresses_imported_data_path
  end

  def when_i_click_on_a_provider_with_address_issue
    click_on @provider_with_issue.operating_name
  end

  def then_i_should_be_taken_to_the_select_new_address_page
    expect(page).to have_current_path(provider_new_select_path(@provider_with_issue, { debug: true }))
  end

  def and_i_should_see_providers_with_address_issues
    expect(page).to have_content(@provider_with_issue.operating_name)
    expect(page).not_to have_content(@provider_without_issue.operating_name)
  end

  def and_there_are_a_provider_with_addresses_issues
    @provider_with_issue = create(:provider, :with_address_issue)
  end

  def and_there_are_a_provider_without_addresses_issues
    @provider_without_issue = create(:provider, :without_address_issue)
  end
end
