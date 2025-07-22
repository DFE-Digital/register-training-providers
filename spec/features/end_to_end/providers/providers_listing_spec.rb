RSpec.feature "Providers List" do
  scenario "User can view paginated list of providers" do
    given_i_am_an_authenticated_user
    and_there_are_a_number_of_providers
    when_i_navigate_to_the_provider_list_page
    then_i_should_see_the_page_title("Providers (26)")
    and_i_should_see_pagination_controls
  end

  def and_there_are_a_number_of_providers
    @providers = create_list(:provider, 26)
  end

  def when_i_navigate_to_the_provider_list_page
    visit providers_path
  end

  def then_i_should_see_the_page_title(title)
    expect(page).to have_title(title)
  end

  def and_i_should_see_pagination_controls
    expect(page).to have_selector(".govuk-pagination")
    expect(page).to have_selector(".govuk-pagination__item", count: 2)
    expect(page).to have_link("Next", href: providers_path(page: 2))
    expect(page).to have_link("2", href: providers_path(page: 2))
    expect(page).to have_link("1", href: providers_path(page: 1))
  end
end
