RSpec.feature "Provider status history" do
  scenario "User can view the provider status history" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_with_provider_status_history
    when_i_visit_the_provider_status_history_page
    then_i_should_see_the_provider_status_history_table
  end

  scenario "User sees a message while there is no provider status history" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_without_provider_status_history
    when_i_visit_the_provider_status_history_page
    then_i_should_see_no_provider_status_history
  end

  def and_there_is_a_provider_with_provider_status_history
    create(:provider_change,
           :baseline,
           provider: subject_provider,
           attribute_name: "status",
           value: { "status" => "active" },
           effective_on: 2.years.ago.to_date)
    create(:provider_change,
           provider: subject_provider,
           attribute_name: "status",
           value: { "status" => "inactive", "reason_ids" => ["no_current_cohorts"] },
           effective_on: 1.year.ago.to_date,
           status: :completed,
           creator: current_user)
    create(:provider_change,
           provider: subject_provider,
           attribute_name: "status",
           value: { "status" => "offboarded" },
           effective_on: 1.month.ago.to_date,
           status: :completed,
           creator: current_user)

    subject_provider.inactive_periods << {
      "start_date" => 1.month.ago.to_date.to_s,
      "end_date" => nil,
      "offboarded" => true
    }
    subject_provider.save!
  end

  def and_there_is_a_provider_without_provider_status_history
    subject_provider
  end

  def current_user
    @current_user ||= create(:user)
  end

  def when_i_visit_the_provider_status_history_page
    visit provider_page

    expect(page).to have_link("History of provider statuses")

    click_on "History of provider statuses"
    and_i_am_taken_to(provider_status_history_page)
  end

  def then_i_should_see_the_provider_status_history_table
    and_i_can_see_the_title("#{subject_provider.operating_name} - Provider status history - Register of training providers - GOV.UK")
    expect(page).to have_back_link(provider_page)
    expect(page).to have_content("View previous provider statuses and when they were changed.")

    expect(page).to have_selector(".govuk-table__header", text: "Provider status")
    expect(page).to have_selector(".govuk-table__header", text: "Reason")
    expect(page).to have_selector(".govuk-table__header", text: "Start date")
    expect(page).to have_selector(".govuk-table__header", text: "End date")
    expect(page).to have_selector(".govuk-table__header", text: "Changed by")
    expect(page).to have_selector(".govuk-table__header", text: "Current")

    expect(all(".govuk-table__body .govuk-table__row").count).to eq(3)

    # first_cell_is_header makes the status value the row header, so the
    # Reason column is the 2nd child and the currency tag the 6th child of the
    # inactive row — pinning the cells to their header columns positionally.
    # The tag describes the change (Current/Scheduled/Superseded), never the
    # status itself, which already sits in the first column.
    within(".govuk-table__body .govuk-table__row", text: "No current cohorts") do
      expect(page).to have_css(".govuk-table__cell:nth-child(2)", text: "No current cohorts")
      expect(page).to have_css(".govuk-table__cell:nth-child(6) .govuk-tag", text: "Superseded")
    end

    within(".govuk-table__body .govuk-table__row", text: "Initial value") do
      expect(page).to have_css(".govuk-tag", text: "Superseded")
      expect(page).to have_content("Active")
    end

    within(".govuk-table__body .govuk-table__row", text: "Offboarded") do
      expect(page).to have_css(".govuk-tag", text: "Current")
      expect(page).to have_content(current_user.name)
    end
  end

  def then_i_should_see_no_provider_status_history
    and_i_can_see_the_title("#{subject_provider.operating_name} - Provider status history - Register of training providers - GOV.UK")
    expect(page).to have_back_link(provider_page)
    expect(page).to have_content("There is no provider status history.")
    expect(page).not_to have_selector(".govuk-table")
  end

  def subject_provider
    @subject_provider ||= create(:provider, operating_name: "Provider with planned changes")
  end

  def and_i_can_see_the_title(title)
    expect(page).to have_title(title)
  end

  def provider_page
    "/providers/#{subject_provider.id}"
  end

  def provider_status_history_page
    "/providers/#{subject_provider.id}/changes/status/history"
  end
end
