RSpec.feature "Editing provider status" do
  scenario "User can mark an active provider as inactive" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_to_change
    when_i_navigate_to_the_provider_page_to_change_status
    and_i_choose_the_inactive_status
    and_i_select_the_reasons_for_inactivity
    and_i_fill_in_the_effective_date_step
    and_i_confirm_the_change_on_the_check_your_answers_step
    then_i_should_be_redirected_to_the_provider_details_page
    and_i_should_see_the_provider_marked_as_inactive
    and_i_should_see_a_success_message
  end

  scenario "User must give a reason why the provider became inactive" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_to_change
    when_i_navigate_to_the_provider_page_to_change_status
    and_i_choose_the_inactive_status
    and_i_select_the_reasons_for_inactivity

    expect(provider_to_change.reload.inactive_periods).to be_empty
    expect(provider_to_change.provider_changes).to be_empty
  end

  scenario "User can end an inactive period to mark the provider as active" do
    given_i_am_an_authenticated_user
    and_there_is_an_inactive_provider_to_change
    when_i_navigate_to_the_provider_page_to_change_status
    and_i_choose_the_active_status
    and_i_fill_in_the_active_from_date
    and_i_confirm_the_active_change_on_the_check_your_answers_step
    then_i_should_be_redirected_to_the_provider_details_page
    and_i_should_see_the_provider_marked_as_active
    and_i_should_see_a_success_message
  end

  scenario "User cannot move back to a status before the inactive period started" do
    given_i_am_an_authenticated_user
    and_there_is_an_inactive_provider_to_change
    when_i_navigate_to_the_provider_page_to_change_status
    and_i_choose_the_active_status

    fill_in "Day", with: (inactive_start - 1.day).day.to_s
    fill_in "Month", with: (inactive_start - 1.day).month.to_s
    fill_in "Year", with: (inactive_start - 1.day).year.to_s

    and_i_click_on("Continue")
    and_i_can_see_the_error_summary("Enter a date that is not within or before an existing period")
  end

  scenario "User can off-board an active provider" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_to_change
    when_i_navigate_to_the_provider_page_to_change_status
    and_i_choose_the_offboarded_status
    and_i_select_the_reasons_for_off_boarding
    and_i_confirm_the_offboarded_change_on_the_check_your_answers_step
    then_i_should_be_redirected_to_the_provider_details_page
    and_i_should_see_the_provider_marked_as_offboarded
    and_i_should_see_a_success_message
  end

  scenario "User can give a free-text reason via the Another reason checkbox" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_to_change
    when_i_navigate_to_the_provider_page_to_change_status
    and_i_choose_the_inactive_status
    and_i_use_the_another_reason_path
    and_i_fill_in_the_effective_date_step
    and_i_confirm_the_another_reason_change_on_the_check_your_answers_step
    then_i_should_be_redirected_to_the_provider_details_page
    and_i_should_see_the_provider_marked_as_inactive_with_another_reason
  end

  scenario "Confirming the same status change twice does not write a second history row" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_to_change
    when_i_navigate_to_the_provider_page_to_change_status
    and_i_choose_the_inactive_status
    and_i_select_the_reasons_for_inactivity
    and_i_fill_in_the_effective_date_step(effective_from: effective_on_today)
    and_i_confirm_the_change_on_the_check_your_answers_step(effective_from: effective_on_today)
    then_i_should_be_redirected_to_the_provider_details_page
    and_i_should_see_the_provider_marked_as_inactive_from_today

    and_i_resubmit_the_stale_confirm_page
    then_i_should_be_redirected_to_the_provider_details_page
    and_i_should_see_a_success_message

    and_only_one_history_row_is_recorded
  end

  scenario "User landing directly on a later step is redirected to the first step" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_to_change
    when_i_navigate_to_the_provider_page_to_change_status

    visit("/providers/#{provider_to_change.id}/changes/status/effective-date")
    and_i_am_taken_to("/providers/#{provider_to_change.id}/changes/status/new-status")
  end

  def and_i_confirm_the_change_on_the_check_your_answers_step(effective_from: effective_on)
    expect(page).to have_link("Back", href: "/providers/#{provider_to_change.id}/changes/status/effective-date")

    and_i_can_see_the_title("#{provider_to_change.operating_name} - Check your answers - Register of training providers - GOV.UK")

    within("dl.govuk-summary-list") do
      within(".govuk-summary-list__row", text: "Current status") do
        expect(page).to have_css(".govuk-summary-list__value", text: "Active")
      end

      within(".govuk-summary-list__row", text: "New status") do
        expect(page).to have_css(".govuk-summary-list__value", text: "Inactive")
        expect(page).to have_link(
          "Change new status",
          href: "/providers/#{provider_to_change.id}/changes/status/new-status?return_to_review=new_status"
        )
      end

      within(".govuk-summary-list__row", text: "Reason") do
        expect(page).to have_css(".govuk-summary-list__value", text: "No current cohorts")
        expect(page).to have_link(
          "Change reason",
          href: "/providers/#{provider_to_change.id}/changes/status/reasons?return_to_review=reasons"
        )
      end

      within(".govuk-summary-list__row", text: "Effective date") do
        expect(page).to have_css(".govuk-summary-list__value", text: effective_from.to_fs(:govuk))
        expect(page).to have_link(
          "Change effective date",
          href: "/providers/#{provider_to_change.id}/changes/status/effective-date?return_to_review=effective_date"
        )
      end
    end

    and_i_click_on("Confirm and continue")
  end

  def and_i_confirm_the_active_change_on_the_check_your_answers_step
    expect(page).to have_link("Back", href: "/providers/#{provider_to_change.id}/changes/status/effective-date")

    within("dl.govuk-summary-list") do
      within(".govuk-summary-list__row", text: "Current status") do
        expect(page).to have_css(".govuk-summary-list__value", text: "Inactive")
      end

      within(".govuk-summary-list__row", text: "New status") do
        expect(page).to have_css(".govuk-summary-list__value", text: "Active")
      end
    end

    expect(page).not_to have_css(".govuk-summary-list__row", text: "Reason")

    and_i_click_on("Confirm and continue")
  end

  def and_i_confirm_the_offboarded_change_on_the_check_your_answers_step
    and_i_can_see_the_title("#{provider_to_change.operating_name} - Check your answers - Register of training providers - GOV.UK")

    within("dl.govuk-summary-list") do
      within(".govuk-summary-list__row", text: "New status") do
        expect(page).to have_css(".govuk-summary-list__value", text: "Offboarded")
      end

      within(".govuk-summary-list__row", text: "Reason") do
        expect(page).to have_css(".govuk-summary-list__value", text: "No current cohorts")
      end
    end

    and_i_click_on("Confirm and continue")
  end

  def and_i_choose_the_inactive_status
    expect(page).to have_link("Back", href: "/providers/#{provider_to_change.id}")
    and_i_can_see_the_title("#{provider_to_change.operating_name} - What is the new provider status? - Register of training providers - GOV.UK")
    and_i_do_not_see_error_summary

    choose("Inactive")
    and_i_click_on("Continue")
    and_i_am_taken_to("/providers/#{provider_to_change.id}/changes/status/reasons")
  end

  def and_i_choose_the_offboarded_status
    choose("Offboarded")
    and_i_click_on("Continue")
    and_i_am_taken_to("/providers/#{provider_to_change.id}/changes/status/reasons")
  end

  def and_i_select_the_reasons_for_inactivity
    expect(page).to have_link("Back", href: "/providers/#{provider_to_change.id}/changes/status/new-status")
    and_i_can_see_the_title("#{provider_to_change.operating_name} - Why did the provider become inactive? - Register of training providers - GOV.UK")
    and_i_do_not_see_error_summary

    and_i_click_on("Continue")
    and_i_can_see_the_error_summary("Select at least one reason")

    check "No current cohorts"
    and_i_click_on("Continue")
    and_i_am_taken_to("/providers/#{provider_to_change.id}/changes/status/effective-date")
  end

  def and_i_use_the_another_reason_path
    check "Another reason"
    within("div.govuk-checkboxes__conditional") do
      expect(page).to have_field("Enter the reason")
    end

    and_i_click_on("Continue")
    and_i_can_see_the_error_summary("Enter a reason")

    fill_in "Enter the reason", with: "x" * 256
    and_i_click_on("Continue")
    and_i_can_see_the_error_summary("The reason must be 255 characters or fewer")

    fill_in "Enter the reason", with: another_reason
    and_i_click_on("Continue")
    and_i_am_taken_to("/providers/#{provider_to_change.id}/changes/status/effective-date")
  end

  def and_i_confirm_the_another_reason_change_on_the_check_your_answers_step
    within("dl.govuk-summary-list") do
      within(".govuk-summary-list__row", text: "Reason") do
        expect(page).to have_css(".govuk-summary-list__value", text: another_reason)
        expect(page).to have_link(
          "Change reason",
          href: "/providers/#{provider_to_change.id}/changes/status/reasons?return_to_review=reasons"
        )
      end
    end

    and_i_click_on("Change reason")
    expect(page).to have_checked_field("Another reason")
    expect(page).to have_field("Enter the reason", with: another_reason)
    and_i_click_on("Continue")
    and_i_am_taken_to("/providers/#{provider_to_change.id}/changes/status/check-your-answers")
    and_i_click_on("Confirm and continue")
  end

  def and_i_should_see_the_provider_marked_as_inactive_with_another_reason
    provider_to_change.reload

    pending_change = provider_to_change.provider_changes.pending.for_attribute("status").sole

    expect(pending_change.value).to eq(
      "status" => "inactive",
      "reason_ids" => ["other"],
      "other_reason" => another_reason
    )
    expect(pending_change.effective_on).to eq(effective_on)
  end

  def and_i_select_the_reasons_for_off_boarding
    and_i_can_see_the_title("#{provider_to_change.operating_name} - Why was the provider offboarded? - Register of training providers - GOV.UK")

    check "No current cohorts"
    and_i_click_on("Continue")
    and_i_am_taken_to("/providers/#{provider_to_change.id}/changes/status/effective-date")

    and_i_can_see_the_title("#{provider_to_change.operating_name} - When was the provider offboarded? - Register of training providers - GOV.UK")

    fill_in "Day", with: Time.zone.today.day.to_s
    fill_in "Month", with: Time.zone.today.month.to_s
    fill_in "Year", with: Time.zone.today.year.to_s
    and_i_click_on("Continue")

    and_i_am_taken_to("/providers/#{provider_to_change.id}/changes/status/check-your-answers")
  end

  def and_i_fill_in_the_effective_date_step(effective_from: effective_on)
    expect(page).to have_link("Back", href: "/providers/#{provider_to_change.id}/changes/status/reasons")
    and_i_can_see_the_title("#{provider_to_change.operating_name} - When did the provider become inactive? - Register of training providers - GOV.UK")
    and_i_do_not_see_error_summary

    expect(page).to have_css(
      ".govuk-hint",
      text: "The provider has existed since #{provider_to_change.onboarded_at.to_fs(:govuk)}"
    )

    and_i_click_on("Continue")
    and_i_can_see_the_error_summary("Enter date that the status change applies from")

    fill_in "Day", with: effective_from.day.to_s
    fill_in "Month", with: effective_from.month.to_s
    fill_in "Year", with: effective_from.year.to_s
    and_i_click_on("Continue")

    and_i_am_taken_to("/providers/#{provider_to_change.id}/changes/status/check-your-answers")
  end

  def and_i_choose_the_active_status
    expect(page).to have_link("Back", href: "/providers/#{provider_to_change.id}")
    and_i_can_see_the_title("#{provider_to_change.operating_name} - What is the new provider status? - Register of training providers - GOV.UK")

    choose("Active")
    and_i_click_on("Continue")
    and_i_am_taken_to("/providers/#{provider_to_change.id}/changes/status/effective-date")
  end

  def and_i_fill_in_the_active_from_date
    and_i_can_see_the_title("#{provider_to_change.operating_name} - When did the provider become active? - Register of training providers - GOV.UK")

    fill_in "Day", with: inactive_start.day.to_s
    fill_in "Month", with: inactive_start.month.to_s
    fill_in "Year", with: inactive_start.year.to_s
    and_i_click_on("Continue")
    and_i_am_taken_to("/providers/#{provider_to_change.id}/changes/status/check-your-answers")
  end

  def and_i_should_see_the_provider_marked_as_inactive
    provider_to_change.reload

    pending_change = provider_to_change.provider_changes.pending.for_attribute("status").sole

    expect(provider_to_change).not_to be_inactive
    expect(pending_change.value).to eq(
      "status" => "inactive",
      "reason_ids" => ["no_current_cohorts"]
    )
    expect(pending_change.effective_on).to eq(effective_on)
  end

  def and_i_should_see_the_provider_marked_as_inactive_from_today
    provider_to_change.reload

    expect(provider_to_change.status).to eq("inactive")
    expect(provider_to_change.inactive?).to be(true)
    expect(provider_to_change.current_inactive_period["start_date"]).to eq(Time.zone.today.to_s)
    expect(provider_to_change.current_inactive_period["reasons_for_inactive"]).to eq(["No current cohorts"])
  end

  def and_i_resubmit_the_stale_confirm_page
    page.driver.submit(
      :patch,
      "/providers/#{provider_to_change.id}/changes/status/check-your-answers",
      {}
    )
  end

  def and_only_one_history_row_is_recorded
    changes = provider_to_change.reload.provider_changes.for_attribute("status")

    expect(changes.baseline.count).to eq(1)

    applied_change = changes.requested.sole

    expect(applied_change).to have_attributes(
      value: { "status" => "inactive", "reason_ids" => ["no_current_cohorts"] },
      status: "completed"
    )
  end

  def and_i_should_see_the_provider_marked_as_active
    provider_to_change.reload

    expect(provider_to_change).not_to be_inactive
    expect(provider_to_change.status).to eq("active")
  end

  def and_i_should_see_the_provider_marked_as_offboarded
    provider_to_change.reload

    expect(provider_to_change.open_offboarded_period).to be_present
    expect(provider_to_change.status).to eq("offboarded")
    expect(provider_to_change.offboarded_period["reasons_for_inactive"]).to eq(["No current cohorts"])
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
      "Success", "Provider status change request submitted successfully"
    )
  end

  def then_i_should_be_redirected_to_the_provider_details_page
    and_i_am_taken_to("/providers/#{provider_to_change.id}")
  end

  def when_i_navigate_to_the_provider_page_to_change_status
    visit "/providers"
    click_on provider_to_change.operating_name
    and_i_am_taken_to("/providers/#{provider_to_change.id}")
    and_i_click_on("Change provider status")
    and_i_am_taken_to("/providers/#{provider_to_change.id}/changes/status/new-status")
  end

  def effective_on
    @effective_on ||= Time.zone.today + 1.month
  end

  def effective_on_today
    @effective_on_today ||= Time.zone.today
  end

  def another_reason
    @another_reason ||= "Rebuilding the curriculum for a September relaunch"
  end

  def inactive_start
    @inactive_start ||= Time.zone.today - 1.month
  end

  def and_there_is_a_provider_to_change
    provider_to_change
  end

  def and_there_is_an_inactive_provider_to_change
    provider_to_change.inactive_periods << {
      "start_date" => inactive_start.to_s,
      "end_date" => nil,
      "reasons_for_inactive" => ["No current cohorts"]
    }
    provider_to_change.save!
  end

  def provider_to_change
    @provider_to_change ||= create(
      :provider,
      operating_name: "Provider with a status to change",
      first_active_at: inactive_start - 1.day,
      onboarded_at: inactive_start - 1.day
    )
  end
end
