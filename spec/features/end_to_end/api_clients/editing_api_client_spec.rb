require "rails_helper"

RSpec.feature "Api client management" do
  scenario "editing api_clients" do
    given_i_am_an_authenticated_user
    and_i_have_a_api_client_to_edit
    and_i_am_on_the_api_client_support_listing_page
    and_i_can_see_the_page_title_api_clients_with_the_count(count: 2)

    and_i_click_on(api_client_to_edit.name)
    and_i_am_taken_to("/api_clients/#{api_client_to_edit.id}")

    and_i_can_see_the_page_title_for_view_api_client
    and_i_click_on("Change")
    and_i_am_taken_to("/api_clients/#{api_client_to_edit.id}/edit")

    and_i_can_see_the_page_title_for_personal_details
    and_i_do_not_see_error_summary
    and_i_fill_in_the_name_incorrectly

    and_i_click_on("Continue")
    and_i_can_see_the_error_summary
    and_i_can_see_the_page_title_for_personal_details_with_error

    and_i_fill_in_the_name

    and_i_click_on("Continue")

    and_i_am_taken_to("/api_clients/#{api_client_to_edit.id}/check")
    and_i_click_on("Back")

    and_i_am_taken_to("/api_clients/#{api_client_to_edit.id}/edit?goto=confirm")
    and_i_click_on("Continue")

    and_i_can_see_the_page_title_for_check_your_answers
    and_i_show_see_new_name
    when_i_click_on("Save api client")

    then_i_see_the_success_message
    and_i_am_taken_to("/api_clients")

    and_i_can_see_the_page_title_api_clients_with_the_count(count: 2)
    and_i_cannot_find(old_api_client_to_edit_name)
    and_the_api_client_to_edit_is_edited
    and_i_see_my_changes(api_client_to_edit.name)
  end

  def and_i_show_see_new_name
    expect(page).to have_css(".govuk-summary-list__value", text: new_name)
  end

  def and_i_fill_in_the_name_incorrectly
    page.fill_in "Client name", with: ""
  end

  def and_i_fill_in_the_name
    page.fill_in "Client name", with: new_name
  end

  def and_the_api_client_to_edit_is_edited
    expect(api_client_to_edit.reload.name).to eq(new_name)
  end

  def new_name
    "New client"
  end

  def old_name
    "Old client"
  end

  def and_i_see_my_changes(link)
    expect(page).to have_link(link)
  end

  def and_i_cannot_find(button_or_link)
    expect(page).not_to have_button(button_or_link)
    expect(page).not_to have_link(button_or_link)
  end

  def and_i_can_see_the_page_title_api_clients_with_the_count(count: 1)
    expect(page).to have_title("API clients (#{count}) - Register of training providers - GOV.UK")
  end

  def and_i_am_on_the_api_client_support_listing_page
    visit "/api_clients"
  end

  def api_client_to_edit
    @api_client_to_edit ||= create(:api_client, name: old_name)
  end

  def old_api_client_to_edit_name
    @old_api_client_to_edit_name ||= api_client_to_edit.name
  end

  alias_method :and_i_have_a_api_client_to_edit, :api_client_to_edit

  def then_i_see_the_success_message
    expect(page).to have_notification_banner("Success", "API client updated")
  end

  def and_i_can_see_the_page_title_for_check_your_answers
    expect(page).to have_title("Change api_client - Register of training providers - GOV.UK")

    expect(page).to have_heading("h1", "API client - #{api_client_to_edit.name}Check your answers")
  end

  def and_i_can_see_the_page_title_for_view_api_client
    expect(page).to have_title("View api_client - Register of training providers - GOV.UK")
  end

  def and_i_can_see_the_page_title_for_personal_details
    expect(page).to have_title("Change api_client - personal details - Register of training providers - GOV.UK")
  end

  def and_i_can_see_the_page_title_for_personal_details_with_error
    expect(page).to have_title("Error: Change api_client - personal details - Register of training providers - GOV.UK")
  end

  def and_i_do_not_see_error_summary
    expect(page).not_to have_error_summary
  end

  def and_i_can_see_the_error_summary
    expect(page).to have_error_summary(
      "Enter Client name",
    )
  end
end
