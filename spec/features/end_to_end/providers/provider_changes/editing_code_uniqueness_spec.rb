RSpec.feature "Editing provider code uniqueness over time" do
  include AcademicYearHelper

  scenario "allows a code when another provider's change has a later effective date" do
    given_i_am_an_authenticated_user
    and_there_are_two_providers
    and_the_other_provider_has_a_pending_code_change(
      code: new_provider_code,
      effective_on: following_academic_year_start_date
    )

    when_i_navigate_to_the_provider_page_to_change_code
    and_i_fill_in_the_effective_academic_year_step(academic_year: :next)
    and_i_fill_in_the_code_step

    then_i_should_be_on_the_check_your_answers_page
  end

  scenario "rejects a code when another provider's change has an earlier effective date" do
    given_i_am_an_authenticated_user
    and_there_are_two_providers
    and_the_other_provider_has_a_pending_code_change(
      code: new_provider_code,
      effective_on: next_academic_year_start_date
    )

    when_i_navigate_to_the_provider_page_to_change_code
    and_i_fill_in_the_effective_academic_year_step(academic_year: :following)
    and_i_fill_in_the_code_step

    then_i_should_see_a_unique_provider_code_error
  end

  scenario "rejects a code when another provider's change has the same effective date" do
    given_i_am_an_authenticated_user
    and_there_are_two_providers
    and_the_other_provider_has_a_pending_code_change(
      code: new_provider_code,
      effective_on: next_academic_year_start_date
    )

    when_i_navigate_to_the_provider_page_to_change_code
    and_i_fill_in_the_effective_academic_year_step(academic_year: :next)
    and_i_fill_in_the_code_step

    then_i_should_see_a_unique_provider_code_error
  end

  scenario "rejects moving another provider's change onto an effective date that is already taken" do
    given_i_am_an_authenticated_user
    and_there_are_two_providers
    and_the_other_provider_has_a_pending_code_change(
      code: new_provider_code,
      effective_on: following_academic_year_start_date
    )

    when_i_navigate_to_the_provider_page_to_change_code
    and_i_fill_in_the_effective_academic_year_step(academic_year: :next)
    and_i_fill_in_the_code_step
    then_i_should_be_on_the_check_your_answers_page
    and_i_confirm_the_change_on_the_check_your_answers_step
    then_i_should_be_redirected_to_the_provider_details_page
    and_i_should_see_a_success_message

    when_i_move_the_other_provider_change_to_an_earlier_effective_date

    and_i_can_see_the_error_summary("Select another academic year")
  end

  scenario "applies a pending code change to the provider once its effective date arrives" do
    given_i_am_an_authenticated_user
    and_there_are_two_providers

    when_i_navigate_to_the_provider_page_to_change_code
    and_i_fill_in_the_effective_academic_year_step(academic_year: :next)
    and_i_fill_in_the_code_step
    and_i_confirm_the_change_on_the_check_your_answers_step
    then_i_should_be_redirected_to_the_provider_details_page
    and_i_should_see_a_success_message

    Timecop.freeze(next_academic_year_start_date) do
      Providers::ApplyProviderChangesJob.new.perform
    end

    expect(provider_code_change(provider_with_code_to_change).reload).to be_completed
    expect(provider_with_code_to_change.reload.code).to eq(new_provider_code)
  end

  scenario "applies the earlier effective change and fails the later change when both become due" do
    given_i_am_an_authenticated_user
    and_there_are_two_providers
    and_the_other_provider_has_a_pending_code_change(
      code: new_provider_code,
      effective_on: following_academic_year_start_date
    )

    when_i_navigate_to_the_provider_page_to_change_code
    and_i_fill_in_the_effective_academic_year_step(academic_year: :next)
    and_i_fill_in_the_code_step
    and_i_confirm_the_change_on_the_check_your_answers_step
    then_i_should_be_redirected_to_the_provider_details_page
    and_i_should_see_a_success_message

    Timecop.freeze(following_academic_year_start_date) do
      Providers::ApplyProviderChangesJob.new.perform
    end

    expect(provider_code_change(provider_with_code_to_change).reload).to be_completed
    expect(provider_with_code_to_change.reload.code).to eq(new_provider_code)

    expect(provider_code_change(other_provider).reload).to be_failed
    expect(provider_code_change(other_provider).error_message).to be_present
    expect(other_provider.reload.code).not_to eq(new_provider_code)
  end

  def provider_code_change(provider)
    provider.provider_changes.find_by(attribute_name: "code")
  end

  def and_there_are_two_providers
    provider_with_code_to_change
    other_provider
  end

  def and_the_other_provider_has_a_pending_code_change(code:, effective_on:)
    create(
      :provider_change,
      provider: other_provider,
      attribute_name: "code",
      value: code,
      effective_on: effective_on
    )
  end

  def when_i_move_the_other_provider_change_to_an_earlier_effective_date
    visit "/providers"
    click_on other_provider.operating_name
    and_i_am_taken_to("/providers/#{other_provider.id}")
    and_i_click_on "Change provider code"
    and_i_am_taken_to("/providers/#{other_provider.id}/changes/code/effective-academic-year")

    expect(page).to have_link("Back", href: "/providers/#{other_provider.id}")
    and_i_can_see_the_title("#{other_provider.operating_name} - When should the provider code change? - Register of training providers - GOV.UK")
    and_i_do_not_see_error_summary

    choose(next_academic_year_label)
    and_i_click_on("Continue")

    and_i_can_see_the_title("Error: #{other_provider.operating_name} - When should the provider code change? - Register of training providers - GOV.UK")
  end

  def when_i_navigate_to_the_provider_page_to_change_code
    visit "/providers"
    click_on provider_with_code_to_change.operating_name
    and_i_am_taken_to("/providers/#{provider_with_code_to_change.id}")
    and_i_click_on "Change provider code"
    and_i_am_taken_to("/providers/#{provider_with_code_to_change.id}/changes/code/effective-academic-year")
  end

  def and_i_fill_in_the_effective_academic_year_step(academic_year:)
    expect(page).to have_link("Back", href: "/providers/#{provider_with_code_to_change.id}")
    and_i_can_see_the_title("#{provider_with_code_to_change.operating_name} - When should the provider code change? - Register of training providers - GOV.UK")
    and_i_do_not_see_error_summary
    and_i_fill_in_the_effective_academic_year_form_incorrectly
    and_i_fill_in_the_effective_academic_year_form_correctly(academic_year)
    and_i_am_taken_to("/providers/#{provider_with_code_to_change.id}/changes/code/new-code")
  end

  def and_i_fill_in_the_code_step
    expect(page).to have_link("Back", href: "/providers/#{provider_with_code_to_change.id}/changes/code/effective-academic-year")
    and_i_can_see_the_title("#{provider_with_code_to_change.operating_name} - What should the provider code change to? - Register of training providers - GOV.UK")
    and_i_do_not_see_error_summary
    and_i_fill_in_the_code_step_incorrectly
    and_i_fill_in_the_code_step_incorrectly_with_same_provider_code
    and_i_fill_in_the_code_step_incorrectly_with_another_existing_provider_code_from_provider
    and_i_fill_in_the_code_step_incorrectly_with_another_existing_provider_code_from_provider_changes

    and_i_fill_in_the_code_step_correctly
  end

  def and_i_confirm_the_change_on_the_check_your_answers_step
    expect(page).to have_link("Back", href: "/providers/#{provider_with_code_to_change.id}/changes/code/new-code")
    and_i_can_see_the_title("#{provider_with_code_to_change.operating_name} - Check your answers - Register of training providers - GOV.UK")
    and_i_click_on("Confirm and continue")
  end

  def then_i_should_be_on_the_check_your_answers_page
    and_i_am_taken_to(
      "/providers/#{provider_with_code_to_change.id}/changes/code/check-your-answers"
    )
  end

  def then_i_should_be_redirected_to_the_provider_details_page
    and_i_am_taken_to("/providers/#{provider_with_code_to_change.id}")
  end

  def then_i_should_see_a_unique_provider_code_error
    and_i_can_see_the_error_summary("Enter a unique provider code")
  end

  def and_i_should_see_a_success_message
    expect(page).to have_notification_banner("Success", "Provider code change request submitted successfully")
  end

  def and_i_fill_in_the_effective_academic_year_form_incorrectly
    and_i_click_on("Continue")
    and_i_can_see_the_error_summary("Select an academic year")

    and_i_can_see_the_title("Error: #{provider_with_code_to_change.operating_name} - When should the provider code change? - Register of training providers - GOV.UK")
  end

  def and_i_fill_in_the_effective_academic_year_form_correctly(academic_year)
    choose(academic_year == :next ? next_academic_year_label : following_academic_year_label)
    and_i_click_on("Continue")
  end

  def and_i_fill_in_the_code_step_incorrectly
    and_i_click_on("Continue")
    and_i_can_see_the_error_summary("Enter provider code")

    and_i_can_see_the_title("Error: #{provider_with_code_to_change.operating_name} - What should the provider code change to? - Register of training providers - GOV.UK")
  end

  def and_i_fill_in_the_code_step_incorrectly_with_same_provider_code
    page.fill_in "Provider code", with: provider_with_code_to_change.code
    and_i_click_on("Continue")
    and_i_can_see_the_error_summary("Enter a unique provider code")

    and_i_can_see_the_title("Error: #{provider_with_code_to_change.operating_name} - What should the provider code change to? - Register of training providers - GOV.UK")
  end

  def and_i_fill_in_the_code_step_incorrectly_with_another_existing_provider_code_from_provider
    page.fill_in "Provider code", with: unrelated_provider_with_existing_code.code
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

  def and_i_fill_in_the_code_step_correctly
    page.fill_in "Provider code", with: new_provider_code

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

  def new_provider_code
    @new_provider_code ||= "L0L"
  end

  def provider_with_code_to_change
    @provider_with_code_to_change ||= create(:provider, code: "R1P")
  end

  def other_provider
    @other_provider ||= create(:provider, code: "C4N")
  end

  def unrelated_provider_with_existing_code
    @unrelated_provider_with_existing_code ||= create(:provider, code: "B4N")
  end

  def unrelated_pending_code_change
    @unrelated_pending_code_change ||= create(:provider_change, value: "DOD", effective_on: next_academic_year_start_date)
  end

  def next_academic_year_label
    @next_academic_year_label ||= academic_year_label(AcademicYearCalculator.next_academic_year)
  end

  def following_academic_year_label
    @following_academic_year_label ||= academic_year_label(AcademicYearCalculator.following_academic_year)
  end

  def next_academic_year_start_date
    AcademicYearCalculator.build_academic_year_start_date(AcademicYearCalculator.next_academic_year)
  end

  def following_academic_year_start_date
    AcademicYearCalculator.build_academic_year_start_date(AcademicYearCalculator.following_academic_year)
  end
end
