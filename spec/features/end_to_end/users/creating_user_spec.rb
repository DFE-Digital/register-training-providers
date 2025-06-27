require "rails_helper"

RSpec.feature "User management" do
  scenario "creating users" do
    given_i_am_an_authenticated_user
    and_i_am_on_the_user_support_listing_page
    and_i_can_see_the_page_title_support_users_with_the_count
    and_i_click_on("Add user")
    and_i_am_taken_to("/users/new")
    and_i_can_see_the_page_title_for_personal_details
    and_i_do_not_see_error_summary

    and_i_click_on("Continue")
    and_i_can_see_the_error_summary
    and_i_can_see_the_page_title_for_personal_details_with_error

    and_i_fill_in_the_personal_details_correctly
    and_i_click_on("Continue")
    and_i_am_taken_to("/users/check/new")
    and_i_can_see_the_page_title_for_check_your_answers
    when_i_click_on("Save user")
    and_i_am_taken_to("/users")

    then_i_see_the_success_message
    and_i_can_see_the_page_title_support_users_with_the_count(count: 2)
  end

  def and_i_can_see_the_page_title_support_users_with_the_count(count: 1)
    expect(page).to have_title("Support users (#{count}) - Register of training providers - GOV.UK")
  end

  def and_i_am_on_the_user_support_listing_page
    visit "/users"
  end

  def user
    @user ||= build(:user)
  end

  def then_i_see_the_success_message
    expect(page).to have_notification_banner("Success", "Support user added")
  end

  def and_i_can_see_the_page_title_for_check_your_answers
    expect(page).to have_title("Check your answers - Add support user - Register of training providers - GOV.UK")
  end

  def and_i_can_see_the_page_title_for_personal_details_with_error
    expect(page).to have_title("Error: Add support user - personal details - Register of training providers - GOV.UK")
  end

  def and_i_can_see_the_page_title_for_personal_details
    expect(page).to have_title("Add support user - personal details - Register of training providers - GOV.UK")
  end

  def and_i_do_not_see_error_summary
    expect(page).not_to have_error_summary
  end

  def and_i_can_see_the_error_summary
    expect(page).to have_error_summary(
      "Enter first name",
      "Enter last name",
      "Enter email address"
    )
  end

  def and_i_fill_in_the_personal_details_correctly
    page.fill_in "First name", with: user.first_name
    page.fill_in "Last name", with: user.first_name
    page.fill_in "Email", with: user.email
  end
end
