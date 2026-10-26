RSpec.feature "Editing provider type" do
  scenario "User can request a provider type change" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_with_a_provider_type_to_change
    when_i_navigate_to_the_provider_page_to_change_provider_type
    and_i_fill_in_the_effective_date_step
    and_i_select_the_new_provider_type
    and_i_confirm_the_change_on_the_check_your_answers_step
    then_i_should_be_redirected_to_the_provider_details_page
    and_i_should_see_a_success_message
    and_the_provider_type_change_should_be_pending
    and_the_provider_type_change_should_have_recorded_the_baseline
  end

  scenario "User can change a provider type with immediate effect" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_with_a_provider_type_to_change
    @effective_on = Time.zone.today
    when_i_navigate_to_the_provider_page_to_change_provider_type
    and_i_fill_in_the_effective_date_step_with_todays_date
    and_i_select_the_new_provider_type
    and_i_confirm_the_change_on_the_check_your_answers_step
    then_i_should_be_redirected_to_the_provider_details_page
    and_i_should_see_a_success_message
    and_the_provider_type_should_be_updated
  end

  scenario "User can edit an existing pending provider type change" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_with_a_provider_type_to_change_with_an_existing_change
    when_i_navigate_to_the_provider_page_to_change_provider_type
    then_i_should_see_the_existing_effective_date_prefilled
    and_i_fill_in_the_effective_date_step(skip_validation_round_trip: true)
    and_i_select_the_new_provider_type(skip_validation_round_trip: true)
    and_i_confirm_the_change_on_the_check_your_answers_step
    then_i_should_be_redirected_to_the_provider_details_page
    and_i_should_see_a_success_message

    expect(existing_provider_change.reload.value).to eq("scitt")
  end

  scenario "User can change a provider type to Other" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_with_a_provider_type_to_change
    when_i_navigate_to_the_provider_page_to_change_provider_type
    and_i_fill_in_the_effective_date_step
    and_i_select_the_new_provider_type(select_provider_type: "Other")
    and_i_confirm_the_change_on_the_check_your_answers_step(expected_type: "Other")
    then_i_should_be_redirected_to_the_provider_details_page
    and_i_should_see_a_success_message

    expect(
      provider_with_provider_type_change.provider_changes.pending.for_attribute("provider_type").sole.value
    ).to eq("other")
  end

  scenario "User cannot select the provider's current provider type" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_with_a_provider_type_to_change
    when_i_navigate_to_the_provider_page_to_change_provider_type
    and_i_fill_in_the_effective_date_step
    and_i_select_the_current_provider_type
    then_i_should_see_a_provider_type_error("Select a different provider type")
  end

  scenario "User landing directly on a later step is redirected to the first step" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_with_a_provider_type_to_change

    visit("/providers/#{provider_with_provider_type_change.id}/changes/provider_type/new-provider-type")
    and_i_am_taken_to("/providers/#{provider_with_provider_type_change.id}/changes/provider_type/effective-date")

    visit("/providers/#{provider_with_provider_type_change.id}/changes/provider_type/check-your-answers")
    and_i_am_taken_to("/providers/#{provider_with_provider_type_change.id}/changes/provider_type/effective-date")
  end

  def and_i_confirm_the_change_on_the_check_your_answers_step(expected_type: new_provider_type_label)
    and_i_can_see_the_title("#{provider_with_provider_type_change.operating_name} - Check your answers - Register of training providers - GOV.UK")

    within("dl.govuk-summary-list") do
      within(".govuk-summary-list__row", text: "Old provider type") do
        expect(page).to have_css(".govuk-summary-list__value", text: "School")
      end

      within(".govuk-summary-list__row", text: "New provider type") do
        expect(page).to have_css(".govuk-summary-list__value", text: expected_type)
        expect(page).to have_link(
          "Change new provider type",
          href: "/providers/#{provider_with_provider_type_change.id}/changes/provider_type/new-provider-type?return_to_review=new_provider_type"
        )
      end

      within(".govuk-summary-list__row", text: "Effective date") do
        expect(page).to have_css(".govuk-summary-list__value", text: effective_on.to_fs(:govuk))
        expect(page).to have_link(
          "Change effective date",
          href: "/providers/#{provider_with_provider_type_change.id}/changes/provider_type/effective-date?return_to_review=effective_date"
        )
      end
    end

    and_i_click_on("Confirm and continue")
  end

  def and_i_fill_in_the_effective_date_step(skip_validation_round_trip: false)
    expect(page).to have_link("Back", href: "/providers/#{provider_with_provider_type_change.id}")
    and_i_can_see_the_title("#{provider_with_provider_type_change.operating_name} - When should the provider type change? - Register of training providers - GOV.UK")
    and_i_do_not_see_error_summary

    and_i_fill_in_the_effective_date_form_incorrectly unless skip_validation_round_trip
    and_i_fill_in_the_effective_date_form_correctly
    and_i_am_taken_to("/providers/#{provider_with_provider_type_change.id}/changes/provider_type/new-provider-type")
  end

  def and_i_fill_in_the_effective_date_form_incorrectly
    and_i_click_on("Continue")
    and_i_can_see_the_error_summary("Enter effective on")
  end

  def and_i_fill_in_the_effective_date_form_correctly
    fill_in "Day", with: effective_on.day.to_s
    fill_in "Month", with: effective_on.month.to_s
    fill_in "Year", with: effective_on.year.to_s

    and_i_click_on("Continue")
  end

  def and_i_fill_in_the_effective_date_step_with_todays_date
    expect(page).to have_link("Back", href: "/providers/#{provider_with_provider_type_change.id}")
    and_i_can_see_the_title("#{provider_with_provider_type_change.operating_name} - When should the provider type change? - Register of training providers - GOV.UK")

    fill_in "Day", with: Time.zone.today.day.to_s
    fill_in "Month", with: Time.zone.today.month.to_s
    fill_in "Year", with: Time.zone.today.year.to_s

    and_i_click_on("Continue")
    and_i_am_taken_to("/providers/#{provider_with_provider_type_change.id}/changes/provider_type/new-provider-type")
  end

  def and_i_select_the_new_provider_type(select_provider_type: new_provider_type_label, skip_validation_round_trip: false)
    and_i_can_see_the_title("#{provider_with_provider_type_change.operating_name} - What should the provider type change to? - Register of training providers - GOV.UK")
    and_i_do_not_see_error_summary

    unless skip_validation_round_trip
      and_i_click_on("Continue")
      and_i_can_see_the_error_summary("Select provider type")
    end

    choose select_provider_type
    and_i_click_on("Continue")
    and_i_am_taken_to("/providers/#{provider_with_provider_type_change.id}/changes/provider_type/check-your-answers")
  end

  def and_i_select_the_current_provider_type
    choose "School"
    and_i_click_on("Continue")
  end

  def then_i_should_see_a_provider_type_error(message)
    and_i_can_see_the_error_summary(message)
    and_i_can_see_the_title("Error: #{provider_with_provider_type_change.operating_name} - What should the provider type change to? - Register of training providers - GOV.UK")
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
      "Success", "Provider type change request submitted successfully"
    )
  end

  def then_i_should_be_redirected_to_the_provider_details_page
    and_i_am_taken_to("/providers/#{provider_with_provider_type_change.id}")
  end

  def and_the_provider_type_change_should_be_pending
    change = provider_with_provider_type_change.provider_changes.pending.for_attribute("provider_type").sole

    expect(change.value).to eq("scitt")
    expect(change.effective_on).to eq(effective_on)
    expect(provider_with_provider_type_change.reload.provider_type).to eq("school")
  end

  def and_the_provider_type_change_should_have_recorded_the_baseline
    baseline = provider_with_provider_type_change.provider_changes.baseline.for_attribute("provider_type").sole

    expect(baseline).to have_attributes(
      value: "school",
      status: "completed",
      effective_on: provider_with_provider_type_change.created_at.to_date
    )
    expect(baseline.creator).to be_nil
  end

  def and_the_provider_type_should_be_updated
    expect(provider_with_provider_type_change.reload.provider_type).to eq("scitt")

    changes = provider_with_provider_type_change.provider_changes.for_attribute("provider_type")
    expect(changes.pending).to be_empty
    expect(changes.completed).to be_present
  end

  def then_i_should_see_the_existing_effective_date_prefilled
    expect(page).to have_field("Day", with: effective_on.day.to_s)
    expect(page).to have_field("Month", with: effective_on.month.to_s)
    expect(page).to have_field("Year", with: effective_on.year.to_s)
  end

  def when_i_navigate_to_the_provider_page_to_change_provider_type
    visit "/providers"
    click_on provider_with_provider_type_change.operating_name
    and_i_am_taken_to("/providers/#{provider_with_provider_type_change.id}")
    and_i_click_on "Change provider type"
    and_i_am_taken_to("/providers/#{provider_with_provider_type_change.id}/changes/provider_type/effective-date")
  end

  def and_there_is_a_provider_with_a_provider_type_to_change
    provider_with_provider_type_change
  end

  def and_there_is_a_provider_with_a_provider_type_to_change_with_an_existing_change
    existing_provider_change
  end

  def existing_provider_change
    @existing_provider_change ||= create(
      :provider_change,
      provider: provider_with_provider_type_change,
      attribute_name: "provider_type",
      value: "hei",
      effective_on: effective_on
    )
  end

  def new_provider_type_label
    "School-centred initial teacher training (SCITT)"
  end

  def effective_on
    @effective_on ||= Time.zone.today + 1.month
  end

  def provider_with_provider_type_change
    @provider_with_provider_type_change ||= create(
      :provider,
      operating_name: "Provider with type",
      provider_type: :school
    )
  end
end
