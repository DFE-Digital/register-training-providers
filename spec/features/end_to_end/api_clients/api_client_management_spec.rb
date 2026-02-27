require "rails_helper"

RSpec.feature "Api Client management" do
  scenario "api_clients listing can be viewed" do
    given_i_am_an_authenticated_user
    and_there_are_a_number_of_api_clients
    when_i_click_on_the_the_api_clients_in_the_navigation_bar
    then_i_can_see_the_page_title_api_clients_with_the_count
    and_a_table_of_api_clients
    and_the_table_has_header_for_name_and_email
  end

  def when_i_click_on_the_the_api_clients_in_the_navigation_bar
    click_link("API clients", class: "govuk-service-navigation__link")
  end

  def and_there_are_a_number_of_api_clients
    api_clients
  end

  def api_clients
    @api_clients ||= create_list(:api_client, 25, :with_authentication_token)
  end

  def and_i_sign_in_via_dfe_sign_in
    and_i_visit_the_sign_in_page
  end

  def then_i_can_see_the_page_title_api_clients_with_the_count
    expect(page).to have_title("API clients (25) - Register of training providers - GOV.UK")
  end

  def and_a_table_of_api_clients
    row_count = all(".govuk-table__body .govuk-table__row").count
    expect(row_count).to eq(25)
  end

  def and_the_table_has_header_for_name_and_email
    expect(page).to have_selector(".govuk-table__header", text: "Client name")
    expect(page).to have_selector(".govuk-table__header", text: "Expires on")
    expect(page).to have_selector(".govuk-table__header", text: "Status")
  end
end
