RSpec.feature "Provider accreditation history" do
  scenario "User can view the provider accreditation history with active and inactive accreditations" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_with_accreditations
    and_there_is_a_history_link_on_the_provider_page
    when_i_follow_the_history_link
    then_i_should_see_the_provider_accreditation_history_table
  end

  scenario "User can view the provider accreditation history when there is none" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_without_accreditations
    when_i_visit_the_provider_accreditation_history_page_directly
    then_i_should_see_no_provider_accreditation_history
  end

  def and_there_is_a_provider_with_accreditations
    provider.accreditations.destroy_all
    provider.update!(accreditation_status: :accredited)

    create(:accreditation,
           provider: provider,
           number: "1001",
           start_date: 4.years.ago.to_date,
           end_date: 2.years.ago.to_date)
    create(:accreditation,
           provider: provider,
           number: "1002",
           start_date: 2.years.ago.to_date,
           end_date: nil)
    create(:accreditation,
           provider: provider,
           number: "1003",
           start_date: 1.year.from_now.to_date,
           end_date: 3.years.from_now.to_date)
  end

  def and_there_is_a_provider_without_accreditations
    @provider = create(:provider, operating_name: "Provider without accreditations")

    provider.accreditations.destroy_all
    provider.update!(accreditation_status: :unaccredited)
  end

  def and_there_is_a_history_link_on_the_provider_page
    visit provider_page
    expect(page).to have_link("History of accreditation numbers")
  end

  def when_i_follow_the_history_link
    click_on "History of accreditation numbers"
    and_i_am_taken_to(accreditation_history_page)
  end

  def when_i_visit_the_provider_accreditation_history_page_directly
    visit accreditation_history_page
  end

  def then_i_should_see_the_provider_accreditation_history_table
    and_i_can_see_the_title("#{provider.operating_name} - Accreditation number history - Register of training providers - GOV.UK")
    expect(page).to have_back_link(provider_page)
    expect(page).to have_content("View previous accreditation numbers and when they were in effect.")

    expect(page).to have_selector(".govuk-table__header", text: "Accreditation number")
    expect(page).to have_selector(".govuk-table__header", text: "Start date")
    expect(page).to have_selector(".govuk-table__header", text: "End date")
    expect(page).to have_selector(".govuk-table__header", text: "Status")

    rows = all(".govuk-table__body .govuk-table__row")
    expect(rows.count).to eq(3)
    expect(rows[0]).to have_text("1001")
    expect(rows[1]).to have_text("1002")
    expect(rows[2]).to have_text("1003")

    within(rows[0]) do
      expect(page).to have_css(".govuk-tag", text: "Inactive")
    end

    within(rows[1]) do
      expect(page).to have_css(".govuk-tag", text: "Active")
    end

    within(rows[2]) do
      expect(page).to have_css(".govuk-tag", text: "Inactive")
    end
  end

  def then_i_should_see_no_provider_accreditation_history
    and_i_can_see_the_title("Provider without accreditations - Accreditation number history - Register of training providers - GOV.UK")
    expect(page).to have_back_link(provider_page)
    expect(page).to have_content("There is no accreditation number history.")
    expect(page).not_to have_selector(".govuk-table")
  end

  def and_i_am_taken_to(path)
    expect(page).to have_current_path(path)
  end

  def and_i_can_see_the_title(title)
    expect(page).to have_title(title)
  end

  def provider
    @provider ||= create(:provider, :hei, operating_name: "Provider with accreditations")
  end

  def provider_page
    "/providers/#{provider.id}"
  end

  def accreditation_history_page
    "/providers/#{provider.id}/accreditation-history"
  end
end
