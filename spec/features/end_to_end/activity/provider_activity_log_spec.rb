RSpec.feature "Provider Activity Log" do
  scenario "User can view activity log for a provider via tab navigation" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_with_activity
    when_i_visit_the_provider_page
    and_i_click_the_activity_log_tab
    then_i_should_see_the_provider_activity_log_page
    and_the_activity_log_tab_should_be_active
    and_i_should_see_the_activity_count
    and_i_should_see_activity_items_for_this_provider
  end

  scenario "User only sees activity for the specific provider" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_with_activity
    and_there_is_another_provider_with_activity
    when_i_visit_the_provider_activity_log
    then_i_should_only_see_activity_for_my_provider
  end

  scenario "User sees empty state when provider has no activity" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_without_tracked_activity
    when_i_visit_the_provider_activity_log
    then_i_should_see_the_empty_state
  end

  def and_there_is_a_provider_with_activity
    Audited.audit_class.as_user(user) do
      @provider = create(:provider)
      @address = create(:address, provider: @provider)
    end
  end

  def and_there_is_another_provider_with_activity
    Audited.audit_class.as_user(user) do
      @other_provider = create(:provider)
      create(:contact, provider: @other_provider)
    end
  end

  def and_there_is_a_provider_without_tracked_activity
    @provider = create(:provider)
    Audited::Audit.delete_all
  end

  def when_i_visit_the_provider_page
    visit provider_path(@provider)
  end

  def when_i_visit_the_provider_activity_log
    visit provider_activity_path(@provider)
  end

  def and_i_click_the_activity_log_tab
    within(".app-secondary-navigation") do
      click_on "Activity log"
    end
  end

  def then_i_should_see_the_provider_activity_log_page
    expect(page).to have_current_path(provider_activity_path(@provider))
    expect(page).to have_heading("h1", @provider.operating_name)
  end

  def and_the_activity_log_tab_should_be_active
    within(".app-secondary-navigation") do
      expect(page).to have_selector(".app-secondary-navigation__item--active", text: "Activity log")
    end
  end

  def and_i_should_see_the_activity_count
    expect(page).to have_heading("h2", /Activity \(\d+\)/)
  end

  def and_i_should_see_activity_items_for_this_provider
    expect(page).to have_text("Provider added")
    expect(page).to have_text("Provider address added")
    expect(page).to have_text("By #{user.name}")
  end

  def then_i_should_only_see_activity_for_my_provider
    expect(page).to have_text("Provider added")
    expect(page).to have_text("Provider address added")
    expect(page).not_to have_text("Provider contact added")
  end

  def then_i_should_see_the_empty_state
    expect(page).to have_text("There is no activity to show.")
  end

  def user
    @user ||= create(:user)
  end

  def given_i_am_an_authenticated_user
    given_i_am_authenticated(user:)
  end
end
