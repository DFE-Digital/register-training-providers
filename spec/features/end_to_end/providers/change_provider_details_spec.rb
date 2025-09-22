RSpec.feature "Change Provider Details" do
  scenario "User can update provider details" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider
    when_i_navigate_to_the_change_provider_details_page_for_a_specific_provider
    and_i_fill_out_the_provider_form_with_updated_details
    and_i_checked_my_answers
    then_i_should_be_redirected_to_the_provider_details_page
    then_i_see_the_success_message
  end

  def when_i_navigate_to_the_change_provider_details_page_for_a_specific_provider
    visit "/providers"
    and_i_click_on(provider.operating_name)
    and_i_am_taken_to("/providers/#{provider.id}")
    and_i_click_on("Change operating name")
  end

  def and_i_fill_out_the_provider_form_with_updated_details
    expect(TemporaryRecord.count).to eq(0)

    and_i_can_see_the_title("#{provider.operating_name} - Provider details - Register of training providers - GOV.UK")
    and_i_do_not_see_error_summary
    and_i_fill_in_the_provider_details_form(use_incorrect_value: true)

    and_i_click_on("Continue")
    and_i_can_see_the_title("Error: #{provider.operating_name} - Provider details - Register of training providers - GOV.UK")

    and_i_can_see_the_error_summary(
      "Enter operating name",
      "Enter UK provider reference number (UKPRN)",
      "Enter provider code",
      "Enter unique reference number (URN)",
    )

    and_i_fill_in_the_provider_details_form
    and_i_click_on("Continue")
    expect(TemporaryRecord.count).to eq(1)
  end

  def and_i_fill_in_the_provider_details_form(use_incorrect_value: false)
    provider_details.each do |label, value|
      value = nil if use_incorrect_value
      page.fill_in label, with: value
    end
  end

  def and_i_can_see_the_error_summary(*messages)
    expect(page).to have_error_summary(*messages)
  end

  def and_i_can_see_the_title(title)
    expect(page).to have_title(title)
  end

  def and_i_do_not_see_error_summary
    expect(page).not_to have_error_summary
  end

  def then_i_should_be_redirected_to_the_provider_details_page
    and_i_am_taken_to("/providers/#{provider.id}")

    and_the_temporary_record_should_be_cleared
    expect(Provider.count).to eq(1)
    and_i_should_see_all_details_of_the_updated_provider
  end

  def and_the_temporary_record_should_be_cleared
    expect(TemporaryRecord.count).to eq(0)
  end

  def and_i_checked_my_answers
    and_i_am_taken_to("/providers/#{provider.id}/check")
    and_i_can_see_the_title("Check your answers - #{provider.operating_name} - Register of training providers - GOV.UK")
    when_i_click_on("Save provider")
  end

  def then_i_see_the_success_message
    expect(page).to have_notification_banner("Success", "Provider updated")
  end

  def and_i_should_see_all_details_of_the_updated_provider
    expect(page).to have_text(provider_details_to_use.operating_name)
    expect(page).to have_text(provider_details_to_use.provider_type_label)
    expect(page).to have_text(provider_details_to_use.ukprn)
    expect(page).to have_text(provider_details_to_use.code)
    expect(page).to have_text(provider_details_to_use.urn || "Not entered")
    expect(page).to have_text(provider_details_to_use.legal_name || "Not entered")
  end

  def and_there_is_a_provider
    provider
  end

  def provider
    @provider ||= create(:provider, :scitt, :accredited)
  end

  def provider_details_to_use
    @provider_details_to_use ||= build(:provider, provider_type: provider.provider_type, accreditation_status: provider.accreditation_status)
  end

  def provider_details
    @provider_details ||= [
      ["Operating name", provider_details_to_use.operating_name],
      ["Legal name (optional)", provider_details_to_use.legal_name],
      ["UK provider reference number (UKPRN)", provider_details_to_use.ukprn],
      ["Unique reference number (URN)#{" (optional)" unless provider_details_to_use.requires_urn?}", provider_details_to_use.urn],
      ["Provider code", provider_details_to_use.code],
    ]
  end
end
