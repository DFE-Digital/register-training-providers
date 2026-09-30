RSpec.feature "Provider accreditation history" do
  scenario "User can see the accreditation number row in position" do
    given_i_am_an_authenticated_user
    and_there_is_an_accredited_provider_with_a_current_accreditation
    and_i_am_on_the_providers_index
    when_i_click_on_provider_name
    then_i_should_see_the_accreditation_number_row_in_position
  end

  scenario "User can view the provider accreditation history with active and inactive accreditations" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_with_spread_accreditations
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

  def and_there_is_an_accredited_provider_with_a_current_accreditation
    accreditation = build(:accreditation, number: "1002", start_date: 2.years.ago.to_date, end_date: nil)
    @provider = create(:provider, :hei, operating_name: "Provider with accreditations", with_accreditations: false, accreditations: [accreditation])
  end

  def and_there_is_a_provider_with_spread_accreditations
    accreditations = [
      build(:accreditation, number: "1001", start_date: 12.years.ago.to_date, end_date: 8.years.ago.to_date),
      build(:accreditation, number: "1002", start_date: 7.years.ago.to_date, end_date: nil),
      build(:accreditation, number: "1003", start_date: 2.years.from_now.to_date, end_date: 3.years.from_now.to_date),
    ]
    @provider = create(:provider, :hei, operating_name: "Provider with accreditations", with_accreditations: false, accreditations: accreditations)
  end

  def and_there_is_a_provider_without_accreditations
    @provider = create(:provider, operating_name: "Provider without accreditations")
  end

  def and_i_am_on_the_providers_index
    visit providers_path
  end

  def when_i_click_on_provider_name
    click_on "Provider with accreditations"
    and_i_am_taken_to(provider_page)
  end

  def then_i_should_see_the_accreditation_number_row_in_position
    keys = all(".govuk-summary-list__key").map(&:text)
    status_index = keys.index("Accreditation status")
    number_index = keys.index("Accreditation number")
    operating_name_index = keys.index("Operating name")

    expect(number_index).to eq(status_index + 1)
    expect(operating_name_index).to eq(number_index + 1)

    expect(page).to have_content("1002")
    expect(page).to have_link("History of accreditation numbers")
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

    within(".govuk-table__head") do
      %w[Accreditation\ number Start\ date End\ date Status].each do |heading|
        expect(page).to have_css(".govuk-table__header", text: heading)
      end
    end

    numbers_and_status = all(".govuk-table__body .govuk-table__row").map do |row|
      [row.first(".govuk-table__header").text, row.has_css?(".govuk-tag", text: "Active") ? "Active" : "Inactive"]
    end
    expect(numbers_and_status).to eq([%w[1003 Inactive], %w[1002 Active], %w[1001 Inactive]])
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
    @provider ||= create(:provider, operating_name: "Provider with accreditations")
  end

  def provider_page
    "/providers/#{provider.id}"
  end

  def accreditation_history_page
    "/providers/#{provider.id}/accreditation-history"
  end
end
