RSpec.feature "Provider URN history" do
  scenario "User can view the provider URN history showing every change state" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_with_urn_changes
    and_there_is_a_blank_urn_change
    when_i_visit_the_provider_urn_history_page
    then_i_should_see_the_full_provider_urn_history_table
  end

  scenario "User can view the provider URN history when there are no changes" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_without_urn_changes
    when_i_visit_the_provider_urn_history_page
    then_i_should_see_no_provider_urn_history
  end

  def and_there_is_a_provider_with_urn_changes
    create(:provider_change,
           provider: provider_with_urn_changes,
           attribute_name: "urn",
           value: "111111",
           effective_on: 2.years.ago.to_date,
           status: :completed,
           creator: current_user)
    create(:provider_change,
           provider: provider_with_urn_changes,
           attribute_name: "urn",
           value: "222222",
           effective_on: 1.year.ago.to_date,
           status: :completed)
    create(:provider_change,
           provider: provider_with_urn_changes,
           attribute_name: "urn",
           value: "333333",
           effective_on: 3.years.ago.to_date,
           status: :failed)
  end

  def and_there_is_a_blank_urn_change
    create(:provider_change,
           provider: provider_with_urn_changes,
           attribute_name: "urn",
           value: "",
           effective_on: 18.months.ago.to_date,
           status: :completed)
  end

  def when_i_visit_the_provider_urn_history_page
    visit provider_page

    expect(page).to have_link("History of unique reference numbers")
    click_on "History of unique reference numbers"
    and_i_am_taken_to(provider_urn_history_page)
  end

  def then_i_should_see_the_full_provider_urn_history_table
    and_i_can_see_the_title("#{provider_with_urn_changes.operating_name} - Unique reference number (URN) history - Register of training providers - GOV.UK")
    expect(page).to have_back_link(provider_page)
    expect(page).to have_content("View previous unique reference numbers and when they were changed.")

    expect(page).to have_selector(".govuk-table__header", text: "Unique reference number (URN)")
    expect(page).to have_selector(".govuk-table__header", text: "Start date")
    expect(page).to have_selector(".govuk-table__header", text: "End date")
    expect(page).to have_selector(".govuk-table__header", text: "Changed by")
    expect(page).to have_selector(".govuk-table__header", text: "Status")

    expect(all(".govuk-table__body .govuk-table__row").count).to eq(4)

    within(".govuk-table__body .govuk-table__row", text: "222222") do
      expect(page).to have_css(".govuk-tag", text: "Active")
    end

    within(".govuk-table__body .govuk-table__row", text: "111111") do
      expect(page).to have_css(".govuk-tag", text: "Inactive")
      expect(page).to have_content(current_user.name)
    end

    within(".govuk-table__body .govuk-table__row", text: "333333") do
      expect(page).to have_css(".govuk-tag", text: "Error")
    end

    within(".govuk-table__body .govuk-table__row", text: "Not entered") do
      expect(page).to have_css(".govuk-tag", text: "Inactive")
    end
  end

  def and_there_is_a_provider_without_urn_changes
    provider_with_urn_changes
  end

  def then_i_should_see_no_provider_urn_history
    and_i_can_see_the_title("#{provider_with_urn_changes.operating_name} - Unique reference number (URN) history - Register of training providers - GOV.UK")
    expect(page).to have_back_link(provider_page)
    expect(page).to have_content("There is no unique reference number history.")
    expect(page).not_to have_selector(".govuk-table")
  end

  def provider_with_urn_changes
    @provider_with_urn_changes ||= create(:provider, :scitt, operating_name: "Provider with URN changes")
  end

  def and_i_can_see_the_title(title)
    expect(page).to have_title(title)
  end

  def provider_page
    "/providers/#{provider_with_urn_changes.id}"
  end

  def provider_urn_history_page
    "/providers/#{provider_with_urn_changes.id}/changes/urn/history"
  end
end
