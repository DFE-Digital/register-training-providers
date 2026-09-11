RSpec.feature "Editing provider code" do
  include AcademicYearHelper

  scenario "User can edit a provider code" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_with_code_to_change
    when_i_navigate_to_the_provider_page_to_change_code
    and_i_fill_in_the_effective_academic_year_step
    and_i_fill_in_the_code_step
    and_i_confirm_the_change_on_the_check_your_answers_step
    then_i_should_be_redirected_to_the_provider_details_page
    and_i_should_see_a_success_message
  end

  scenario "User can edit an existing provider code change" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_with_code_to_change_with_existing_provider_change_for_provider_code
    when_i_navigate_to_the_provider_page_to_change_code
    and_i_fill_in_the_effective_academic_year_step(skip_validation_round_trip: true)
    and_i_fill_in_the_code_step(skip_validation_round_trip: true)
    and_i_confirm_the_change_on_the_check_your_answers_step
    then_i_should_be_redirected_to_the_provider_details_page
    and_i_should_see_a_success_message

    expect {
      existing_provider_change_for_provider_with_code_to_change.reload
    }.to change { existing_provider_change_for_provider_with_code_to_change.value }.from("POP").to(new_provider_code)
  end

  scenario "User landing directly on a later step is redirected to the first step" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_with_code_to_change

    visit("/providers/#{provider_with_code_to_change.id}/changes/code/new-code")
    and_i_am_taken_to("/providers/#{provider_with_code_to_change.id}/changes/code/effective-academic-year")

    visit("/providers/#{provider_with_code_to_change.id}/changes/code/check-your-answers")
    and_i_am_taken_to("/providers/#{provider_with_code_to_change.id}/changes/code/effective-academic-year")
  end

  def and_there_is_a_provider_with_code_to_change_with_existing_provider_change_for_provider_code
    existing_provider_change_for_provider_with_code_to_change
  end

  def and_i_confirm_the_change_on_the_check_your_answers_step
    expect(page).to have_link("Back", href: "/providers/#{provider_with_code_to_change.id}/changes/code/new-code")

    and_i_can_see_the_title("#{provider_with_code_to_change.operating_name} - Check your answers - Register of training providers - GOV.UK")
    and_i_change_the_new_code_and_effective_date_from_the_check_your_answers_page
    and_i_click_on("Confirm and continue")
  end

  def and_i_change_the_new_code_and_effective_date_from_the_check_your_answers_page
    within("dl.govuk-summary-list") do
      within(".govuk-summary-list__row", text: "Old provider code") do
        expect(page).to have_css(".govuk-summary-list__value", text: provider_with_code_to_change.code)
      end

      within(".govuk-summary-list__row", text: "New provider code") do
        expect(page).to have_css(".govuk-summary-list__value", text: new_provider_code)
        expect(page).to have_link(
          "Change new provider code",
          href: "/providers/#{provider_with_code_to_change.id}/changes/code/new-code?return_to_review=new_code"
        )
      end

      within(".govuk-summary-list__row", text: "Effective on") do
        expect(page).to have_css(
          ".govuk-summary-list__value",
          text: following_academic_year_label
        )
        expect(page).to have_link(
          "Change effective on",
          href: "/providers/#{provider_with_code_to_change.id}/changes/code/effective-academic-year?return_to_review=effective_academic_year"
        )
      end
    end

    click_on "Change new provider code"
    and_i_am_taken_to("/providers/#{provider_with_code_to_change.id}/changes/code/new-code?return_to_review=new_code")

    click_on "Continue"
    and_i_am_taken_to("/providers/#{provider_with_code_to_change.id}/changes/code/check-your-answers")

    click_on "Change effective on"
    and_i_am_taken_to("/providers/#{provider_with_code_to_change.id}/changes/code/effective-academic-year?return_to_review=effective_academic_year")
    click_on "Continue"
    and_i_am_taken_to("/providers/#{provider_with_code_to_change.id}/changes/code/check-your-answers")
  end

  def and_i_fill_in_the_code_step(skip_validation_round_trip: false)
    expect(page).to have_link("Back", href: "/providers/#{provider_with_code_to_change.id}/changes/code/effective-academic-year")
    and_i_can_see_the_title("#{provider_with_code_to_change.operating_name} - What should the provider code change to? - Register of training providers - GOV.UK")
    and_i_do_not_see_error_summary
    and_i_fill_in_the_code_step_incorrectly unless skip_validation_round_trip
    and_i_fill_in_the_code_step_incorrectly_with_same_provider_code
    and_i_fill_in_the_code_step_incorrectly_with_another_existing_provider_code_from_provider
    and_i_fill_in_the_code_step_incorrectly_with_another_existing_provider_code_from_provider_changes

    and_i_fill_in_the_code_step_correctly
    and_i_am_taken_to("/providers/#{provider_with_code_to_change.id}/changes/code/check-your-answers")
  end

  def and_i_fill_in_the_code_step_incorrectly_with_same_provider_code
    page.fill_in "Provider code", with: provider_with_code_to_change.code
    and_i_click_on("Continue")
    and_i_can_see_the_error_summary("Enter a unique provider code")

    and_i_can_see_the_title("Error: #{provider_with_code_to_change.operating_name} - What should the provider code change to? - Register of training providers - GOV.UK")
  end

  def and_i_fill_in_the_code_step_incorrectly_with_another_existing_provider_code_from_provider_changes
    page.fill_in "Provider code", with: unrelated_pending_code_change.value
    and_i_click_on("Continue")
    and_i_can_see_the_error_summary("Enter a unique provider code")

    and_i_can_see_the_title("Error: #{provider_with_code_to_change.operating_name} - What should the provider code change to? - Register of training providers - GOV.UK")
  end

  def and_i_fill_in_the_code_step_incorrectly_with_another_existing_provider_code_from_provider
    page.fill_in "Provider code", with: existing_provider.code
    and_i_click_on("Continue")
    and_i_can_see_the_error_summary("Enter a unique provider code")

    and_i_can_see_the_title("Error: #{provider_with_code_to_change.operating_name} - What should the provider code change to? - Register of training providers - GOV.UK")
  end

  def and_i_fill_in_the_code_step_incorrectly
    and_i_click_on("Continue")
    and_i_can_see_the_error_summary("Enter provider code")

    and_i_can_see_the_title("Error: #{provider_with_code_to_change.operating_name} - What should the provider code change to? - Register of training providers - GOV.UK")
  end

  def new_provider_code
    @new_provider_code ||= "L0L"
  end

  def and_i_fill_in_the_code_step_correctly
    page.fill_in "Provider code", with: new_provider_code

    and_i_click_on("Continue")
  end

  def and_i_fill_in_the_effective_academic_year_step(skip_validation_round_trip: false)
    expect(page).to have_link("Back", href: "/providers/#{provider_with_code_to_change.id}")
    and_i_can_see_the_title("#{provider_with_code_to_change.operating_name} - When should the provider code change? - Register of training providers - GOV.UK")
    and_i_do_not_see_error_summary
    and_i_fill_in_the_effective_academic_year_form_incorrectly unless skip_validation_round_trip
    and_i_fill_in_the_effective_academic_year_form_correctly
    and_i_am_taken_to("/providers/#{provider_with_code_to_change.id}/changes/code/new-code")
  end

  def and_i_fill_in_the_effective_academic_year_form_incorrectly
    and_i_click_on("Continue")
    and_i_can_see_the_error_summary("Select an academic year")

    and_i_can_see_the_title("Error: #{provider_with_code_to_change.operating_name} - When should the provider code change? - Register of training providers - GOV.UK")
  end

  def following_academic_year_label
    @following_academic_year_label ||= academic_year_label(AcademicYearCalculator.following_academic_year)
  end

  def and_i_fill_in_the_effective_academic_year_form_correctly
    choose(following_academic_year_label)
    and_i_click_on("Continue")
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
    expect(page).to have_notification_banner("Success", "Provider code change request submitted successfully")
  end

  def then_i_should_be_redirected_to_the_provider_details_page
    and_i_am_taken_to("/providers/#{provider_with_code_to_change.id}")
  end

  def when_i_navigate_to_the_provider_page_to_change_code
    visit "/providers"
    click_on provider_with_code_to_change.operating_name
    and_i_am_taken_to("/providers/#{provider_with_code_to_change.id}")
    and_i_click_on "Change provider code"
    and_i_am_taken_to("/providers/#{provider_with_code_to_change.id}/changes/code/effective-academic-year")
  end

  def and_there_is_a_provider_with_code_to_change
    provider_with_code_to_change
  end

  def existing_provider_change_for_provider_with_code_to_change
    @existing_provider_change_for_provider_with_code_to_change ||= create(
      :provider_change, value: "POP", effective_on: following_academic_year_start_date,
                        provider: provider_with_code_to_change
    )
  end

  def unrelated_pending_code_change
    @unrelated_pending_code_change ||= create(:provider_change, value: "DOD", effective_on: following_academic_year_start_date)
  end

  def following_academic_year_start_date
    AcademicYearCalculator.build_academic_year_start_date(AcademicYearCalculator.following_academic_year)
  end

  def existing_provider
    @existing_provider ||= create(:provider, code: "B4N")
  end

  def provider_with_code_to_change
    @provider_with_code_to_change ||= create(:provider, code: "R1P")
  end
end
