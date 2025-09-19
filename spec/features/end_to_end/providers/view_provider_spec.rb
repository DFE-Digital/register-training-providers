RSpec.feature "View Provider" do
  scenario "User can view provider details" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider
    when_i_navigate_to_the_view_provider_page_for_a_specific_provider
    then_i_should_see_the_page_title
    and_i_should_see_all_details_of_the_provider
  end

  def when_i_navigate_to_the_view_provider_page_for_a_specific_provider
    visit "/providers"
    click_on provider.operating_name
    and_i_am_taken_to("/providers/#{provider.id}")
  end

  def then_i_should_see_the_page_title
    expect(page).to have_heading("h2", "Provider details")
    expect(page).to have_heading("h1", provider.operating_name)
    expect(page).to have_title("#{provider.operating_name} - Provider - Register of training providers - GOV.UK")
  end

  def and_i_should_see_all_details_of_the_provider
    expect(page).to have_text(provider.operating_name)
    expect(page).to have_text(provider.provider_type_label)
    expect(page).to have_text(provider.ukprn)
    expect(page).to have_text(provider.code)
    expect(page).to have_text(provider.urn || "Not entered")
    expect(page).to have_text(provider.legal_name || "Not entered")
  end

  def and_there_is_a_provider
    provider
  end

  def provider
    @provider ||= create(:provider)
  end
end
