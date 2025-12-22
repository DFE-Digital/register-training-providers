RSpec.feature "Service Activity Log" do
  scenario "User can view the activity log from navigation" do
    given_i_am_an_authenticated_user
    and_there_is_activity_in_the_system
    when_i_click_activity_log_in_the_navigation
    then_i_should_see_the_activity_log_page
    and_i_should_see_activity_items
    and_i_should_see_summary_cards_with_titles
  end

  scenario "User sees empty state when there is no activity" do
    given_i_am_an_authenticated_user
    and_all_audits_are_cleared
    when_i_visit_the_activity_log_page
    then_i_should_see_the_empty_state
  end

  scenario "User sees pagination when there are many activity items" do
    given_i_am_an_authenticated_user
    and_there_are_many_activity_items
    when_i_visit_the_activity_log_page
    then_i_should_see_pagination_controls
  end

  scenario "User sees partnership activity with dual-link title" do
    given_i_am_an_authenticated_user
    and_there_is_partnership_activity_in_the_system
    when_i_visit_the_activity_log_page
    then_i_should_see_partnership_activity
    and_i_should_see_partnership_summary_card_with_dual_link_title
  end

  def and_there_is_activity_in_the_system
    Audited.audit_class.as_user(user) do
      @provider = create(:provider)
      @contact = create(:contact, provider: @provider)
    end
  end

  def and_there_are_many_activity_items
    Audited.audit_class.as_user(user) do
      create_list(:provider, 26)
    end
  end

  def and_there_is_partnership_activity_in_the_system
    Audited.audit_class.as_user(user) do
      @training_provider = create(:provider)
      @accredited_provider = create(:provider, :accredited)
      @partnership = create(:partnership, provider: @training_provider, accredited_provider: @accredited_provider)
    end
  end

  def when_i_click_activity_log_in_the_navigation
    within(".govuk-service-navigation") do
      click_on "Activity log"
    end
  end

  def when_i_visit_the_activity_log_page
    visit activity_path
  end

  def then_i_should_see_the_activity_log_page
    expect(page).to have_title("Activity log")
    expect(page).to have_heading("h1", "Activity log")
  end

  def and_i_should_see_activity_items
    expect(page).to have_text("Provider added")
    expect(page).to have_text("Provider contact added")
    expect(page).to have_text("By #{user.name}")
  end

  def and_i_should_see_summary_cards_with_titles
    # Service-level activity shows summary cards WITH titles (provider/entity names)
    expect(page).to have_selector(".govuk-summary-card__title", text: @provider.operating_name)
    # Spot-check that card content renders (UKPRN proves provider rows loaded)
    expect(page).to have_selector(".govuk-summary-list__value", text: @provider.ukprn)
  end

  def and_all_audits_are_cleared
    Audited::Audit.delete_all
  end

  def then_i_should_see_the_empty_state
    expect(page).to have_text("There is no activity to show.")
  end

  def then_i_should_see_pagination_controls
    expect(page).to have_selector(".govuk-pagination")
  end

  def then_i_should_see_partnership_activity
    expect(page).to have_text("Provider partnership added")
  end

  def and_i_should_see_partnership_summary_card_with_dual_link_title
    expect(page).to have_selector(
      ".govuk-summary-card__title",
      text: "#{@accredited_provider.operating_name} – #{@training_provider.operating_name}"
    )
    expect(page).to have_selector(".govuk-summary-list__key", text: "Accredited Provider")
    expect(page).to have_selector(".govuk-summary-list__value", text: @accredited_provider.operating_name)
  end

  def user
    @user ||= create(:user)
  end

  def given_i_am_an_authenticated_user
    given_i_am_authenticated(user:)
  end
end
