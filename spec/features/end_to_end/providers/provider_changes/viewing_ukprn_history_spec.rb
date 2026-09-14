RSpec.feature "Provider UKPRN history" do
  scenario "User can view the provider UKPRN history" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_with_ukprn_changes
    when_i_visit_the_provider_ukprn_history_page
    then_i_should_see_the_provider_ukprn_history_table
  end

  scenario "User can view the provider UKPRN history when there are no changes" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_without_ukprn_changes
    when_i_visit_the_provider_ukprn_history_page
    then_i_should_see_no_provider_ukprn_history
  end

  def and_there_is_a_provider_with_ukprn_changes
    create(:provider_change,
           provider: provider_with_ukprn_changes,
           attribute_name: "ukprn",
           value: "11111111",
           effective_on: 2.years.ago.to_date,
           status: :completed,
           creator: current_user)
    create(:provider_change,
           provider: provider_with_ukprn_changes,
           attribute_name: "ukprn",
           value: "22222222",
           effective_on: 1.year.ago.to_date,
           status: :completed)
    create(:provider_change,
           provider: provider_with_ukprn_changes,
           attribute_name: "ukprn",
           value: "33333333",
           effective_on: 3.years.ago.to_date,
           status: :failed)
  end

  def and_there_is_a_provider_without_ukprn_changes
    provider_with_ukprn_changes
  end

  def when_i_visit_the_provider_ukprn_history_page
    visit provider_page

    expect(page).to have_link("History of UK provider reference numbers")
    click_on "History of UK provider reference numbers"
    and_i_am_taken_to(provider_ukprn_history_page)
  end

  def then_i_should_see_the_provider_ukprn_history_table
    and_i_can_see_the_title("#{provider_with_ukprn_changes.operating_name} - UK provider reference number history - Register of training providers - GOV.UK")
    expect(page).to have_back_link(provider_page)
    expect(page).to have_content("View previous UK provider reference numbers and when they were changed.")

    expect(page).to have_selector(".govuk-table__header", text: "UK provider reference number (UKPRN)")
    expect(page).to have_selector(".govuk-table__header", text: "Start date")
    expect(page).to have_selector(".govuk-table__header", text: "End date")
    expect(page).to have_selector(".govuk-table__header", text: "Changed by")
    expect(page).to have_selector(".govuk-table__header", text: "Status")

    expect(all(".govuk-table__body .govuk-table__row").count).to eq(3)

    within(".govuk-table__body .govuk-table__row", text: "22222222") do
      expect(page).to have_css(".govuk-tag", text: "Active")
    end

    within(".govuk-table__body .govuk-table__row", text: "11111111") do
      expect(page).to have_css(".govuk-tag", text: "Inactive")
      expect(page).to have_content(current_user.name)
    end

    within(".govuk-table__body .govuk-table__row", text: "33333333") do
      expect(page).to have_css(".govuk-tag", text: "Error")
    end
  end

  def then_i_should_see_no_provider_ukprn_history
    and_i_can_see_the_title("#{provider_with_ukprn_changes.operating_name} - UK provider reference number history - Register of training providers - GOV.UK")
    expect(page).to have_back_link(provider_page)
    expect(page).to have_content("There is no UK provider reference number history.")
    expect(page).not_to have_selector(".govuk-table")
  end

  def provider_with_ukprn_changes
    @provider_with_ukprn_changes ||= create(:provider, operating_name: "Provider with UKPRN changes")
  end

  def and_i_can_see_the_title(title)
    expect(page).to have_title(title)
  end

  def provider_page
    "/providers/#{provider_with_ukprn_changes.id}"
  end

  def provider_ukprn_history_page
    "/providers/#{provider_with_ukprn_changes.id}/changes/ukprn/history"
  end
end
