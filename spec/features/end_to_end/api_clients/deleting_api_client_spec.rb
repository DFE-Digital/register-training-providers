require "rails_helper"

RSpec.feature "api client management" do
  scenario "deleting API Clients" do
    given_i_am_an_authenticated_user
    and_i_have_a_api_client_to_delete
    and_i_am_on_the_api_client_support_listing_page
    and_i_can_see_the_page_title_api_clients_with_the_count(count: 1)

    and_i_click_on(api_client_to_delete.name)
    and_i_am_taken_to("/api_clients/#{api_client_to_delete.id}")

    and_i_can_see_the_page_title_for_view_api_client
    and_i_click_on("Delete API client")
    and_i_am_taken_to("/api_clients/#{api_client_to_delete.id}/delete")

    and_i_can_see_the_page_title_for_confirm_you_want_to_delete_api_client
    and_i_can_see_the_warning_text
    when_i_click_on("Delete API client")
    then_i_see_the_success_message
    and_i_am_taken_to("/api_clients")

    and_i_can_see_the_page_title_api_clients_with_the_count(count: 0)
    and_i_cannot_find(api_client_to_delete.name)
    and_the_api_client_to_delete_is_deleted
  end

  def and_the_api_client_to_delete_is_deleted
    expect(api_client_to_delete.reload).to be_discarded
  end

  def and_i_cannot_find(button_or_link)
    expect(page).not_to have_button(button_or_link)
    expect(page).not_to have_link(button_or_link)
  end

  def and_i_can_see_the_page_title_api_clients_with_the_count(count: 1)
    expect(page).to have_title("API clients (#{count}) - Register of training providers - GOV.UK")
  end

  def and_i_am_on_the_api(_client_support_listing_page)
    visit "/api_clients"
  end

  def api_client_to_delete
    @api_client_to_delete ||= create(:api_client, :with_authentication_token)
  end

  def and_i_can_see_the_warning_text
    expect(page).to have_warning_text("Deleting an API client is permanent – you cannot undo it.")
  end
  alias_method :and_i_have_a_api_client_to_delete, :api_client_to_delete

  def then_i_see_the_success_message
    expect(page).to have_notification_banner("Success", "API client deleted")
  end

  def and_i_can_see_the_page_title_for_check_your_answers
    expect(page).to have_title("Check your answers - Add api client - Register of training providers - GOV.UK")
  end

  def and_i_can_see_the_page_title_for_confirm_you_want_to_delete_api_client
    expect(page).to have_title("Confirm you want to delete API client - Register of training providers - GOV.UK")
  end

  def and_i_can_see_the_page_title_for_view_api_client
    expect(page).to have_title("View API client - Register of training providers - GOV.UK")
  end

  def and_i_am_on_the_api_client_support_listing_page
    visit "/api_clients"
  end
end
