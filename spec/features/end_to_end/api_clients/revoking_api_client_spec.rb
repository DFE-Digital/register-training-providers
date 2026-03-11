require "rails_helper"

RSpec.feature "api client management" do
  scenario "revoking API Clients" do
    given_i_am_an_authenticated_user
    and_i_have_a_api_client_to_revoke
    and_i_am_on_the_api_client_support_listing_page
    and_i_can_see_the_page_title_api_clients_with_the_count(count: 1)

    and_i_click_on(api_client_to_revoke.name)
    and_i_am_taken_to("/api_clients/#{api_client_to_revoke.id}")

    and_i_can_see_the_page_title_for_view_api_client
    and_i_click_on("Revoke API client")
    and_i_am_taken_to("/api_clients/#{api_client_to_revoke.id}/revoke")

    and_i_can_see_the_page_title_for_confirm_you_want_to_revoke_api_client
    and_i_can_see_the_warning_text
    when_i_click_on("Revoke API client")
    then_i_see_the_success_message
    and_i_am_taken_to("/api_clients")

    and_i_can_see_the_page_title_api_clients_with_the_count(count: 1)
    and_the_api_client_to_revoke_is_revoked
  end

  def and_the_api_client_to_revoke_is_revoked
    expect(api_client_to_revoke.current_authentication_token.reload.status).to eq("revoked")
  end

  def and_i_can_see_the_page_title_api_clients_with_the_count(count: 1)
    expect(page).to have_title("API clients (#{count}) - Register of training providers - GOV.UK")
  end

  def and_i_am_on_the_api(_client_support_listing_page)
    visit "/api_clients"
  end

  def api_client_to_revoke
    @api_client_to_revoke ||= create(:api_client, :with_authentication_token)
  end

  def and_i_can_see_the_warning_text
    expect(page).to have_warning_text("Revoking an API client is permanent – you cannot undo it.")
  end
  alias_method :and_i_have_a_api_client_to_revoke, :api_client_to_revoke

  def then_i_see_the_success_message
    expect(page).to have_notification_banner("Success", "API client revoked")
  end

  def and_i_can_see_the_page_title_for_confirm_you_want_to_revoke_api_client
    expect(page).to have_title("Confirm you want to revoke #{api_client_to_revoke.name} - Register of training providers - GOV.UK")
  end

  def and_i_can_see_the_page_title_for_view_api_client
    expect(page).to have_title("View API client - Register of training providers - GOV.UK")
  end

  def and_i_am_on_the_api_client_support_listing_page
    visit "/api_clients"
  end
end
