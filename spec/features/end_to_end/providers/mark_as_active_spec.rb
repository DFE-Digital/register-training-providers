RSpec.feature "Mark as Active" do
  scenario "User can mark an inactive provider as active" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider
    when_i_navigate_to_the_mark_provider_as_active_page_for_a_specific_provider
    and_i_enter_the_end_date_for_inactivity
    and_i_confirm_that_the_information_is_correct
    then_i_should_be_redirected_to_the_provider_details_page
    and_i_should_see_a_success_message
  end

  def and_i_should_see_a_success_message
    expect(page).to have_notification_banner("Success", "Provider updated")
  end

  def then_i_should_be_redirected_to_the_provider_details_page
    and_i_am_taken_to("/providers/#{provider.id}")

    and_i_should_not_see_the_inactive_status
  end

  def and_i_should_see_the_inactive_status
    expect(page).to have_css(".govuk-tag__heading", text: "Inactive")
  end

  def and_i_should_not_see_the_inactive_status
    expect(page).not_to have_css(".govuk-tag__heading", text: "Inactive")
  end

  def when_i_navigate_to_the_mark_provider_as_active_page_for_a_specific_provider(provider_to_mark_as_active = provider)
    visit "/providers"
    click_on provider_to_mark_as_active.operating_name
    and_i_am_taken_to("/providers/#{provider_to_mark_as_active.id}")
    and_i_should_see_the_inactive_status
    and_i_click_on "Mark as active"
  end

  def and_i_enter_the_end_date_for_inactivity
    within_fieldset("When did the provider become active?") do
      fill_in "Day", with: "1"
      fill_in "Month", with: "1"
      fill_in "Year", with: 1.month.from_now.year.to_s
    end

    and_i_click_on "Continue"
  end

  def and_i_confirm_that_the_information_is_correct
    and_i_click_on "Continue"
  end

  def and_there_is_a_provider
    provider
  end

  def provider
    @provider ||= create(:provider, inactive_periods: [{ start_date: 1.year.ago }])
  end
end
