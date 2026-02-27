require "rails_helper"

RSpec.feature "api_client management" do
  scenario "creating api_clients" do
    given_i_am_an_authenticated_user
    and_i_am_on_the_api_client_support_listing_page
    and_i_can_see_the_page_title_api_clients_with_the_count(count: 0)
    and_i_click_on("Add API Client")
    and_i_am_taken_to("/api_clients/new")
    and_i_can_see_the_page_title_for_client_details
    and_i_do_not_see_error_summary

    and_i_click_on("Continue")
    and_i_can_see_the_error_summary
    and_i_can_see_the_page_title_for_client_details_with_error

    and_i_fill_in_the_client_details_correctly
    and_i_click_on("Continue")
    and_i_am_taken_to("/api_clients/check/new")
    and_i_can_see_the_page_title_for_check_your_answers
    when_i_click_on("Save API client")
    and_i_am_taken_to("/api_clients/#{saved_api_client.id}/confirmation")

    then_i_see_the_success_message
    when_i_click_on("Back to API clients")
    and_i_am_taken_to("/api_clients")

    and_i_can_see_the_page_title_api_clients_with_the_count(count: 1)
  end

  def and_i_can_see_the_page_title_api_clients_with_the_count(count: 1)
    expect(page).to have_title("API clients (#{count}) - Register of training providers - GOV.UK")
  end

  def and_i_am_on_the_api_client_support_listing_page
    visit "/api_clients"
  end

  def api_client
    @api_client ||= build(:api_client)
  end

  def saved_api_client
    ApiClient.last
  end

  def then_i_see_the_success_message
    expect(page).to have_notification_banner("Success", "API client added")
  end

  def and_i_can_see_the_page_title_for_check_your_answers
    expect(page).to have_title("Check your answers - Add API client - Register of training providers - GOV.UK")
  end

  def and_i_can_see_the_page_title_for_client_details_with_error
    expect(page).to have_title("Error: Add API client - Register of training providers - GOV.UK")
  end

  def and_i_can_see_the_page_title_for_client_details
    expect(page).to have_title("Add API client - Register of training providers - GOV.UK")
  end

  def and_i_do_not_see_error_summary
    expect(page).not_to have_error_summary
  end

  def and_i_can_see_the_error_summary
    expect(page).to have_error_summary(
      "Enter client name",
      "Enter expires at",
    )
  end

  def and_i_fill_in_the_client_details_correctly
    start_year = Date.current.year + 1

    page.fill_in "Client name", with: api_client.name
    within_fieldset("Expiry date") do
      fill_in "Day", with: "1"
      fill_in "Month", with: "1"
      fill_in "Year", with: start_year.to_s
    end
  end
end
