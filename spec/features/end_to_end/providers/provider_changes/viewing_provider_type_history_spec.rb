RSpec.feature "Provider type history" do
  scenario "User can view the provider type history showing human labels" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_with_provider_type_changes
    when_i_visit_the_provider_type_history_page
    then_i_should_see_the_full_provider_type_history_table
  end

  scenario "User can view the provider type history when there are no changes" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_without_provider_type_changes
    when_i_visit_the_provider_type_history_page
    then_i_should_see_no_provider_type_history
  end

  def and_there_is_a_provider_with_provider_type_changes
    create(:provider_change,
           provider: provider_with_provider_type_changes,
           attribute_name: "provider_type",
           value: "hei",
           effective_on: 2.years.ago.to_date,
           status: :completed,
           creator: current_user)
    create(:provider_change,
           provider: provider_with_provider_type_changes,
           attribute_name: "provider_type",
           value: "scitt",
           effective_on: 1.year.ago.to_date,
           status: :completed)
    create(:provider_change,
           provider: provider_with_provider_type_changes,
           attribute_name: "provider_type",
           value: "other",
           effective_on: 3.years.ago.to_date,
           status: :failed)
    create(:provider_change,
           :baseline,
           provider: provider_with_provider_type_changes,
           attribute_name: "provider_type",
           value: "school",
           effective_on: 4.years.ago.to_date)
  end

  def and_there_is_a_provider_without_provider_type_changes
    provider_with_provider_type_changes
  end

  def when_i_visit_the_provider_type_history_page
    visit provider_page

    expect(page).to have_link("History of provider types")
    click_on "History of provider types"
    and_i_am_taken_to(provider_provider_type_history_page)
  end

  def then_i_should_see_the_full_provider_type_history_table
    and_i_can_see_the_title("#{provider_with_provider_type_changes.operating_name} - Provider type history - Register of training providers - GOV.UK")
    expect(page).to have_back_link(provider_page)
    expect(page).to have_content("View previous provider types and when they were changed.")

    expect(page).to have_selector(".govuk-table__header", text: "Provider type")
    expect(page).to have_selector(".govuk-table__header", text: "Start date")
    expect(page).to have_selector(".govuk-table__header", text: "End date")
    expect(page).to have_selector(".govuk-table__header", text: "Changed by")
    expect(page).to have_selector(".govuk-table__header", text: "Status")

    expect(all(".govuk-table__body .govuk-table__row").count).to eq(4)

    expect(page).to have_css("th[scope='row']", text: "Higher education institution (HEI)", exact_text: true)
    expect(page).to have_css("th[scope='row']", text: "School-centred initial teacher training (SCITT)", exact_text: true)
    expect(page).to have_css("th[scope='row']", text: "School", exact_text: true)
    expect(page).to have_css("th[scope='row']", text: "Other", exact_text: true)

    within(".govuk-table__body .govuk-table__row", text: "Higher education institution (HEI)") do
      expect(page).to have_css(".govuk-tag", text: "Inactive")
      expect(page).to have_content(current_user.name)
    end

    within(".govuk-table__body .govuk-table__row", text: "School-centred initial teacher training (SCITT)") do
      expect(page).to have_css(".govuk-tag", text: "Active")
    end

    within(".govuk-table__body .govuk-table__row", text: "Other") do
      expect(page).to have_css(".govuk-tag", text: "Error")
    end

    within(".govuk-table__body .govuk-table__row", text: "Initial value") do
      expect(page).to have_css("th[scope='row']", text: "School", exact_text: true)
    end
  end

  def then_i_should_see_no_provider_type_history
    and_i_can_see_the_title("#{provider_with_provider_type_changes.operating_name} - Provider type history - Register of training providers - GOV.UK")
    expect(page).to have_back_link(provider_page)
    expect(page).to have_content("There is no provider type history.")
    expect(page).not_to have_selector(".govuk-table")
  end

  def provider_with_provider_type_changes
    @provider_with_provider_type_changes ||= create(
      :provider,
      operating_name: "Provider with type changes",
      provider_type: :scitt
    )
  end

  def and_i_can_see_the_title(title)
    expect(page).to have_title(title)
  end

  def provider_page
    "/providers/#{provider_with_provider_type_changes.id}"
  end

  def provider_provider_type_history_page
    "/providers/#{provider_with_provider_type_changes.id}/changes/provider_type/history"
  end
end
