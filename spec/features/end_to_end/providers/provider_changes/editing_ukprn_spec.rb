RSpec.feature "Editing provider UKPRN" do
  scenario "User can edit a provider UKPRN" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_with_ukprn_to_change
    when_i_navigate_to_the_provider_page_to_change_ukprn
    and_i_fill_in_the_effective_date_step
    and_i_fill_in_the_ukprn_step
    and_i_confirm_the_change_on_the_check_your_answers_step
    then_i_should_be_redirected_to_the_provider_details_page
    and_i_should_see_a_success_message
  end

  scenario "User can edit an existing provider UKPRN change" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_with_ukprn_to_change_with_an_existing_change
    when_i_navigate_to_the_provider_page_to_change_ukprn
    then_i_should_see_the_existing_effective_date_prefilled
    and_i_fill_in_the_effective_date_step(skip_validation_round_trip: true)
    and_i_fill_in_the_ukprn_step(skip_validation_round_trip: true)
    and_i_confirm_the_change_on_the_check_your_answers_step
    then_i_should_be_redirected_to_the_provider_details_page
    and_i_should_see_a_success_message

    expect(existing_provider_change.reload.value).to eq(new_ukprn)
  end

  scenario "User landing directly on a later step is redirected to the first step" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_with_ukprn_to_change

    visit("/providers/#{provider_with_ukprn_to_change.id}/changes/ukprn/new-ukprn")
    and_i_am_taken_to("/providers/#{provider_with_ukprn_to_change.id}/changes/ukprn/effective-date")

    visit("/providers/#{provider_with_ukprn_to_change.id}/changes/ukprn/check-your-answers")
    and_i_am_taken_to("/providers/#{provider_with_ukprn_to_change.id}/changes/ukprn/effective-date")
  end

  def and_i_confirm_the_change_on_the_check_your_answers_step
    expect(page).to have_link("Back", href: "/providers/#{provider_with_ukprn_to_change.id}/changes/ukprn/new-ukprn")

    and_i_can_see_the_title("#{provider_with_ukprn_to_change.operating_name} - Check your answers - Register of training providers - GOV.UK")

    within("dl.govuk-summary-list") do
      within(".govuk-summary-list__row", text: "Old UK provider reference number (UKPRN)") do
        expect(page).to have_css(".govuk-summary-list__value", text: provider_with_ukprn_to_change.ukprn)
      end

      within(".govuk-summary-list__row", text: "New UK provider reference number (UKPRN)") do
        expect(page).to have_css(".govuk-summary-list__value", text: new_ukprn)
        expect(page).to have_link(
          "Change new UK provider reference number (UKPRN)",
          href: "/providers/#{provider_with_ukprn_to_change.id}/changes/ukprn/new-ukprn?return_to_review=new_ukprn"
        )
      end

      within(".govuk-summary-list__row", text: "Effective date") do
        expect(page).to have_css(".govuk-summary-list__value", text: effective_on.to_fs(:govuk))
        expect(page).to have_link(
          "Change effective date",
          href: "/providers/#{provider_with_ukprn_to_change.id}/changes/ukprn/effective-date?return_to_review=effective_date"
        )
      end
    end

    and_i_click_on("Confirm and continue")
  end

  def and_i_fill_in_the_effective_date_step(skip_validation_round_trip: false)
    expect(page).to have_link("Back", href: "/providers/#{provider_with_ukprn_to_change.id}")
    and_i_can_see_the_title("#{provider_with_ukprn_to_change.operating_name} - When should the UK provider reference number change? - Register of training providers - GOV.UK")
    and_i_do_not_see_error_summary
    and_i_fill_in_the_effective_date_form_incorrectly unless skip_validation_round_trip
    and_i_fill_in_the_effective_date_form_incorrectly_with_a_past_date unless skip_validation_round_trip
    and_i_fill_in_the_effective_date_form_correctly
    and_i_am_taken_to("/providers/#{provider_with_ukprn_to_change.id}/changes/ukprn/new-ukprn")
  end

  def and_i_fill_in_the_effective_date_form_incorrectly
    and_i_click_on("Continue")
    and_i_can_see_the_error_summary("Enter effective on")

    and_i_can_see_the_title("Error: #{provider_with_ukprn_to_change.operating_name} - When should the UK provider reference number change? - Register of training providers - GOV.UK")
  end

  def and_i_fill_in_the_effective_date_form_incorrectly_with_a_past_date
    past_date = Time.zone.today - 1.day
    fill_in "Day", with: past_date.day.to_s
    fill_in "Month", with: past_date.month.to_s
    fill_in "Year", with: past_date.year.to_s

    and_i_click_on("Continue")
    and_i_can_see_the_error_summary("Effective on must be today or in the future")

    and_i_can_see_the_title("Error: #{provider_with_ukprn_to_change.operating_name} - When should the UK provider reference number change? - Register of training providers - GOV.UK")
  end

  def and_i_fill_in_the_effective_date_form_correctly
    fill_in "Day", with: effective_on.day.to_s
    fill_in "Month", with: effective_on.month.to_s
    fill_in "Year", with: effective_on.year.to_s

    and_i_click_on("Continue")
  end

  def and_i_fill_in_the_ukprn_step(skip_validation_round_trip: false)
    expect(page).to have_link("Back", href: "/providers/#{provider_with_ukprn_to_change.id}/changes/ukprn/effective-date")
    and_i_can_see_the_title("#{provider_with_ukprn_to_change.operating_name} - What should the UK provider reference number change to? - Register of training providers - GOV.UK")
    and_i_do_not_see_error_summary
    and_i_fill_in_the_ukprn_step_incorrectly unless skip_validation_round_trip
    and_i_fill_in_the_ukprn_step_with_the_same_ukprn unless skip_validation_round_trip
    and_i_fill_in_the_ukprn_step_incorrectly_with_an_invalid_ukprn unless skip_validation_round_trip
    and_i_fill_in_the_ukprn_step_correctly
    and_i_am_taken_to("/providers/#{provider_with_ukprn_to_change.id}/changes/ukprn/check-your-answers")
  end

  def and_i_fill_in_the_ukprn_step_incorrectly
    and_i_click_on("Continue")
    and_i_can_see_the_error_summary("Enter UK provider reference number")

    and_i_can_see_the_title("Error: #{provider_with_ukprn_to_change.operating_name} - What should the UK provider reference number change to? - Register of training providers - GOV.UK")
  end

  def and_i_fill_in_the_ukprn_step_with_the_same_ukprn
    page.fill_in "UK provider reference number (UKPRN)", with: provider_with_ukprn_to_change.ukprn
    and_i_click_on("Continue")
    and_i_can_see_the_error_summary("Enter a different UK provider reference number")
  end

  def and_i_fill_in_the_ukprn_step_incorrectly_with_an_invalid_ukprn
    page.fill_in "UK provider reference number (UKPRN)", with: invalid_ukprn
    and_i_click_on("Continue")
    and_i_can_see_the_error_summary("Enter a valid UK provider reference number")

    and_i_can_see_the_title("Error: #{provider_with_ukprn_to_change.operating_name} - What should the UK provider reference number change to? - Register of training providers - GOV.UK")
  end

  def and_i_fill_in_the_ukprn_step_correctly
    page.fill_in "UK provider reference number (UKPRN)", with: new_ukprn

    and_i_click_on("Continue")
  end

  def then_i_should_see_the_existing_effective_date_prefilled
    expect(page).to have_field("Day", with: effective_on.day.to_s)
    expect(page).to have_field("Month", with: effective_on.month.to_s)
    expect(page).to have_field("Year", with: effective_on.year.to_s)
  end

  def and_i_can_see_the_title(title)
    expect(page).to have_title(title)
  end

  def and_i_can_see_the_error_summary(*messages)
    expect(page).to have_error_summary(*messages)
  end

  def and_i_do_not_see_error_summary
    expect(page).not_to have_error_summary
  end

  def and_i_should_see_a_success_message
    expect(page).to have_notification_banner(
      "Success", "UK provider reference number change request submitted successfully"
    )
  end

  def then_i_should_be_redirected_to_the_provider_details_page
    and_i_am_taken_to("/providers/#{provider_with_ukprn_to_change.id}")
  end

  def when_i_navigate_to_the_provider_page_to_change_ukprn
    visit "/providers"
    click_on provider_with_ukprn_to_change.operating_name
    and_i_am_taken_to("/providers/#{provider_with_ukprn_to_change.id}")
    and_i_click_on "Change UK provider reference number (UKPRN)"
    and_i_am_taken_to("/providers/#{provider_with_ukprn_to_change.id}/changes/ukprn/effective-date")
  end

  def and_there_is_a_provider_with_ukprn_to_change
    provider_with_ukprn_to_change
  end

  def and_there_is_a_provider_with_ukprn_to_change_with_an_existing_change
    existing_provider_change
  end

  def existing_provider_change
    @existing_provider_change ||= create(
      :provider_change,
      provider: provider_with_ukprn_to_change,
      attribute_name: "ukprn",
      value: "99999999",
      effective_on: effective_on
    )
  end

  def new_ukprn
    "88888888"
  end

  def invalid_ukprn
    "1234567A"
  end

  def effective_on
    @effective_on ||= Time.zone.today + 1.month
  end

  def provider_with_ukprn_to_change
    @provider_with_ukprn_to_change ||= create(:provider, ukprn: "12345678")
  end
end
