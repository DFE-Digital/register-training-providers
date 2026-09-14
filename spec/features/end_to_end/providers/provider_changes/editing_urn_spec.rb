RSpec.feature "Editing provider URN" do
  scenario "User can edit a provider URN" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_with_urn_to_change
    when_i_navigate_to_the_provider_page_to_change_urn
    and_i_fill_in_the_effective_date_step
    and_i_fill_in_the_urn_step
    and_i_confirm_the_change_on_the_check_your_answers_step
    then_i_should_be_redirected_to_the_provider_details_page
    and_i_should_see_a_success_message
  end

  scenario "User can clear a URN for a provider that does not require one" do
    given_i_am_an_authenticated_user
    provider = create(:provider, :hei, operating_name: "Provider without required URN", urn: "123456")

    visit "/providers"
    click_on provider.operating_name
    and_i_am_taken_to("/providers/#{provider.id}")
    and_i_click_on "Change unique reference number (URN)"
    and_i_am_taken_to("/providers/#{provider.id}/changes/urn/effective-date")

    fill_in "Day", with: Time.zone.today.day.to_s
    fill_in "Month", with: Time.zone.today.month.to_s
    fill_in "Year", with: Time.zone.today.year.to_s
    and_i_click_on("Continue")
    and_i_am_taken_to("/providers/#{provider.id}/changes/urn/new-urn")

    and_i_can_see_the_title("#{provider.operating_name} - What should the unique reference number (URN) change to? - Register of training providers - GOV.UK")
    and_i_click_on("Continue")
    and_i_am_taken_to("/providers/#{provider.id}/changes/urn/check-your-answers")

    and_i_click_on("Confirm and continue")
    and_i_am_taken_to("/providers/#{provider.id}")

    expect(provider.reload.urn).to be_blank
  end

  scenario "User can edit an existing provider URN change" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_with_urn_to_change_with_an_existing_change
    when_i_navigate_to_the_provider_page_to_change_urn
    then_i_should_see_the_existing_effective_date_prefilled
    and_i_fill_in_the_effective_date_step(skip_validation_round_trip: true)
    and_i_fill_in_the_urn_step(skip_validation_round_trip: true)
    and_i_confirm_the_change_on_the_check_your_answers_step
    then_i_should_be_redirected_to_the_provider_details_page
    and_i_should_see_a_success_message

    expect(existing_provider_change.reload.value).to eq(new_urn)
  end

  scenario "User landing directly on a later step is redirected to the first step" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_with_urn_to_change

    visit("/providers/#{provider_with_urn_to_change.id}/changes/urn/new-urn")
    and_i_am_taken_to("/providers/#{provider_with_urn_to_change.id}/changes/urn/effective-date")

    visit("/providers/#{provider_with_urn_to_change.id}/changes/urn/check-your-answers")
    and_i_am_taken_to("/providers/#{provider_with_urn_to_change.id}/changes/urn/effective-date")
  end

  def and_i_confirm_the_change_on_the_check_your_answers_step
    expect(page).to have_link("Back", href: "/providers/#{provider_with_urn_to_change.id}/changes/urn/new-urn")

    and_i_can_see_the_title("#{provider_with_urn_to_change.operating_name} - Check your answers - Register of training providers - GOV.UK")

    within("dl.govuk-summary-list") do
      within(".govuk-summary-list__row", text: "Old unique reference number (URN)") do
        expect(page).to have_css(".govuk-summary-list__value", text: provider_with_urn_to_change.urn)
      end

      within(".govuk-summary-list__row", text: "New unique reference number (URN)") do
        expect(page).to have_css(".govuk-summary-list__value", text: new_urn)
        expect(page).to have_link(
          "Change new unique reference number (urn)",
          href: "/providers/#{provider_with_urn_to_change.id}/changes/urn/new-urn?return_to_review=new_urn"
        )
      end

      within(".govuk-summary-list__row", text: "Effective date") do
        expect(page).to have_css(".govuk-summary-list__value", text: effective_on.to_fs(:govuk))
        expect(page).to have_link(
          "Change effective date",
          href: "/providers/#{provider_with_urn_to_change.id}/changes/urn/effective-date?return_to_review=effective_date"
        )
      end
    end

    and_i_click_on("Confirm and continue")
  end

  def and_i_fill_in_the_effective_date_step(skip_validation_round_trip: false)
    expect(page).to have_link("Back", href: "/providers/#{provider_with_urn_to_change.id}")
    and_i_can_see_the_title("#{provider_with_urn_to_change.operating_name} - When should the unique reference number (URN) change? - Register of training providers - GOV.UK")
    and_i_do_not_see_error_summary
    and_i_fill_in_the_effective_date_form_incorrectly unless skip_validation_round_trip
    and_i_fill_in_the_effective_date_form_correctly
    and_i_am_taken_to("/providers/#{provider_with_urn_to_change.id}/changes/urn/new-urn")
  end

  def and_i_fill_in_the_effective_date_form_incorrectly
    and_i_click_on("Continue")
    and_i_can_see_the_error_summary("Enter effective on")

    and_i_can_see_the_title("Error: #{provider_with_urn_to_change.operating_name} - When should the unique reference number (URN) change? - Register of training providers - GOV.UK")
  end

  def and_i_fill_in_the_effective_date_form_correctly
    fill_in "Day", with: effective_on.day.to_s
    fill_in "Month", with: effective_on.month.to_s
    fill_in "Year", with: effective_on.year.to_s

    and_i_click_on("Continue")
  end

  def and_i_fill_in_the_urn_step(skip_validation_round_trip: false)
    expect(page).to have_link("Back", href: "/providers/#{provider_with_urn_to_change.id}/changes/urn/effective-date")
    and_i_can_see_the_title("#{provider_with_urn_to_change.operating_name} - What should the unique reference number (URN) change to? - Register of training providers - GOV.UK")
    and_i_do_not_see_error_summary
    and_i_fill_in_the_urn_step_incorrectly unless skip_validation_round_trip
    and_i_fill_in_the_urn_step_with_the_same_urn unless skip_validation_round_trip
    and_i_fill_in_the_urn_step_correctly
    and_i_am_taken_to("/providers/#{provider_with_urn_to_change.id}/changes/urn/check-your-answers")
  end

  def and_i_fill_in_the_urn_step_incorrectly
    and_i_click_on("Continue")
    and_i_can_see_the_error_summary("Enter unique reference number (URN)")

    and_i_can_see_the_title("Error: #{provider_with_urn_to_change.operating_name} - What should the unique reference number (URN) change to? - Register of training providers - GOV.UK")
  end

  def and_i_fill_in_the_urn_step_with_the_same_urn
    page.fill_in "Unique reference number (URN)", with: provider_with_urn_to_change.urn
    and_i_click_on("Continue")
    and_i_can_see_the_error_summary("Enter a different unique reference number (URN)")
  end

  def and_i_fill_in_the_urn_step_correctly
    page.fill_in "Unique reference number (URN)", with: new_urn

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
      "Success", "Unique reference number change request submitted successfully"
    )
  end

  def then_i_should_be_redirected_to_the_provider_details_page
    and_i_am_taken_to("/providers/#{provider_with_urn_to_change.id}")
  end

  def when_i_navigate_to_the_provider_page_to_change_urn
    visit "/providers"
    click_on provider_with_urn_to_change.operating_name
    and_i_am_taken_to("/providers/#{provider_with_urn_to_change.id}")
    and_i_click_on "Change unique reference number (URN)"
    and_i_am_taken_to("/providers/#{provider_with_urn_to_change.id}/changes/urn/effective-date")
  end

  def and_there_is_a_provider_with_urn_to_change
    provider_with_urn_to_change
  end

  def and_there_is_a_provider_with_urn_to_change_with_an_existing_change
    existing_provider_change
  end

  def existing_provider_change
    @existing_provider_change ||= create(
      :provider_change,
      provider: provider_with_urn_to_change,
      attribute_name: "urn",
      value: "999999",
      effective_on: effective_on
    )
  end

  def new_urn
    "654321"
  end

  def effective_on
    @effective_on ||= Time.zone.today + 1.month
  end

  def provider_with_urn_to_change
    @provider_with_urn_to_change ||= create(:provider, :scitt, urn: "123456")
  end
end
