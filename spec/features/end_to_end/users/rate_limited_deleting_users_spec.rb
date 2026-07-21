require "rails_helper"

RSpec.feature "User management" do
  scenario "rate limited of a user deleting users" do
    given_i_am_an_authenticated_user
    and_i_have_users_to_delete
    and_i_am_on_the_user_support_listing_page
    and_i_can_see_the_page_title_users_with_the_count(count: 5)

    Timecop.freeze(Time.zone.now) do
      users_to_delete.each do |user_to_delete|
        and_i_click_on(user_to_delete.name)
        and_i_am_taken_to("/users/#{user_to_delete.id}")

        and_i_click_on("Delete user2")
        and_i_am_taken_to("/users/#{user_to_delete.id}/delete")

        when_i_click_on("Delete user")
        then_i_see_the_success_message
        and_i_am_taken_to("/users")
      end
      and_i_can_see_the_page_title_users_with_the_count(count: 2)

      and_i_click_on(user_fails_to_be_deleted.name)
      and_i_am_taken_to("/users/#{user_fails_to_be_deleted.id}")

      and_i_click_on("Delete user")
      and_i_am_taken_to("/users/#{user_fails_to_be_deleted.id}/delete")

      expect(Rails.logger).to receive(:warn).with(
        event: "too_many_requests",
        user_id: current_user.id,
        controller: "Users::DeletesController",
        action: "destroy",
        path: "/users/#{user_fails_to_be_deleted.id}/delete",
      )

      when_i_click_on("Delete user")
      and_i_can_see_the_page_title_for_not_able_to_complete_this_action
      and_i_am_still_on("/users/#{user_fails_to_be_deleted.id}/delete")
    end
  end

  def and_the_user_to_delete_is_deleted
    expect(user_to_delete.reload).to be_discarded
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

  def and_i_have_users_to_delete
    users_to_delete
    user_fails_to_be_deleted
  end

  def users_to_delete
    @users_to_delete ||= create_list(:user, 3)
  end

  def user_fails_to_be_deleted
    @user_fails_to_be_deleted ||= create(:user)
  end

  def and_i_can_see_the_warning_text
    expect(page).to have_warning_text("Deleting a user is permanent – you cannot undo it.")
  end

  def then_i_see_the_success_message
    expect(page).to have_notification_banner("Success", "User deleted")
  end

  def and_i_can_see_the_page_title_for_check_your_answers
    expect(page).to have_title("Check your answers - Add user - Register of training providers - GOV.UK")
  end

  def and_i_can_see_the_page_title_for_confirm_you_want_to_delete_user
    expect(page).to have_title("Confirm you want to delete user - Register of training providers - GOV.UK")
  end

  def and_i_can_see_the_page_title_for_view_user
    expect(page).to have_title("View user - Register of training providers - GOV.UK")
  end

  def and_i_can_see_the_page_title_for_not_able_to_complete_this_action
    expect(page).to have_title("Sorry, there’s a problem completing this action - Register of training providers - GOV.UK")
  end
end
