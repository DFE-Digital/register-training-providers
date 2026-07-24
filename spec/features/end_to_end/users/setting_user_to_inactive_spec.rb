require "rails_helper"

RSpec.feature "User management" do
  scenario "editing users" do
    given_i_am_an_authenticated_user
    and_i_have_a_user_to_set_to_inactive
    and_i_am_on_the_user_support_listing_page
    and_i_can_see_the_page_title_users_with_the_count(count: 2)

    and_i_click_on(user_to_deactivate.name)
    and_i_can_see_the_page_title_for_view_user
    and_i_click_on("Change is the account active?")
    and_i_am_taken_to("/users/#{user_to_deactivate.id}/edit")

    and_i_can_see_the_page_title_for_personal_details
    and_i_do_not_see_error_summary

    and_i_set_the_user_to_inactive

    and_i_click_on("Continue")

    and_i_am_taken_to("/users/#{user_to_deactivate.id}/check")

    and_i_can_see_the_page_title_for_check_your_answers

    expect(Rails.logger).to receive(:warn).with(
      event: "user_deactivated",
      user_id: current_user.id,
      deactivate_user_id: user_to_deactivate.id,
    )

    when_i_click_on("Save user")

    then_i_see_the_success_message
    and_i_am_taken_to("/users")

    and_i_can_see_the_page_title_users_with_the_count(count: 2)
  end

  def and_i_set_the_user_to_inactive
    page.choose("No", name: "user[active]")
  end

  def and_the_user_to_deactivate_is_edited
    expect(user_to_deactivate.reload.first_name).to eq(new_first_name)
  end

  def new_first_name
    "Nouveau"
  end

  def old_first_name
    "Vieux"
  end

  def and_i_see_my_changes(link)
    expect(page).to have_link(link)
  end

  def and_i_cannot_find(button_or_link)
    expect(page).not_to have_button(button_or_link)
    expect(page).not_to have_link(button_or_link)
  end

  def and_i_can_see_the_page_title_users_with_the_count(count: 1)
    expect(page).to have_title("Users (#{count}) - Register of training providers - GOV.UK")
  end

  def and_i_am_on_the_user_support_listing_page
    visit "/users"
  end

  def user_to_deactivate
    @user_to_deactivate ||= create(:user, first_name: old_first_name)
  end

  def old_user_to_deactivate_name
    @old_user_to_deactivate_name ||= user_to_deactivate.name
  end

  alias_method :and_i_have_a_user_to_set_to_inactive, :user_to_deactivate

  def then_i_see_the_success_message
    expect(page).to have_notification_banner("Success", "User updated")
  end

  def and_i_can_see_the_page_title_for_check_your_answers
    expect(page).to have_title("Change user - Register of training providers - GOV.UK")

    expect(page).to have_heading("h1", "User - #{user_to_deactivate.name}Check your answers")
  end

  def and_i_can_see_the_page_title_for_view_user
    expect(page).to have_title("View user - Register of training providers - GOV.UK")
  end

  def and_i_can_see_the_page_title_for_personal_details
    expect(page).to have_title("Change user - personal details - Register of training providers - GOV.UK")
  end

  def and_i_can_see_the_page_title_for_personal_details_with_error
    expect(page).to have_title("Error: Change user - personal details - Register of training providers - GOV.UK")
  end

  def and_i_do_not_see_error_summary
    expect(page).not_to have_error_summary
  end

  def and_i_can_see_the_error_summary
    expect(page).to have_error_summary(
      "Enter first name",
    )
  end
end
