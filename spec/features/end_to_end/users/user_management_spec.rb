require "rails_helper"

RSpec.feature "User management" do
  scenario "Users listing can be viewed" do
    given_i_am_an_authenticated_user
    and_there_are_a_number_of_support_users
    when_i_click_on_the_the_support_users_in_the_navigation_bar
    then_i_can_see_the_page_title_support_users_with_the_count
    and_a_table_of_support_users
    and_the_table_has_header_for_name_and_email
  end

  def when_i_click_on_the_the_support_users_in_the_navigation_bar
    click_link('Support users', class: 'govuk-service-navigation__link')
  end

  def and_there_are_a_number_of_support_users
    users
  end

  def users
    @users ||= create_list(:user, 24)
  end

  def and_i_sign_in_via_dfe_sign_in
    and_i_visit_the_sign_in_page
  end

  def then_i_can_see_the_page_title_support_users_with_the_count
    expect(page).to have_title("Support users (25) - Register of training providers - GOV.UK")
  end

  def and_a_table_of_support_users
    row_count = all('.govuk-table__body .govuk-table__row').count
    expect(row_count).to eq(25)
  end

  def and_the_table_has_header_for_name_and_email
    expect(page).to have_selector('.govuk-table__header', text: 'Name')
    expect(page).to have_selector('.govuk-table__header', text: 'Email')
  end
end
