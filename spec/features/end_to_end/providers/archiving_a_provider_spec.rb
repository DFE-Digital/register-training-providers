RSpec.feature "Archive Provider" do
  scenario "User can archive a provider" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider
    when_i_navigate_to_the_archive_provider_page_for_a_specific_provider
    and_i_confirm_archiving_the_provider
    then_i_should_be_redirected_to_the_provider_details_page
    and_i_should_see_a_success_message
  end

  scenario "Accreditation buttons are not available after archiving a provider" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider_with_an_accreditation
    and_i_archive_the_provider
    when_i_navigate_to_the_provider_accreditations_page
    then_i_should_not_see_accreditation_action_buttons
  end

  def and_i_should_see_a_success_message
    expect(page).to have_notification_banner("Success", "Provider archived")
  end

  def then_i_should_be_redirected_to_the_provider_details_page
    and_i_am_taken_to("/providers/#{provider.id}")

    and_i_should_see_the_archive_status
  end

  def and_i_should_see_the_archive_status
    expect(page).to have_css(".govuk-tag__heading", text: "Archived")
    expect(page).to have_link("Restore", href: provider_restore_path(provider))
    expect(page).to have_link("Delete", href: provider_delete_path(provider))
  end

  def when_i_navigate_to_the_archive_provider_page_for_a_specific_provider(provider_to_archive = provider)
    visit "/providers"
    click_on provider_to_archive.operating_name
    and_i_am_taken_to("/providers/#{provider_to_archive.id}")
    and_i_click_on "Archive provider"
  end

  def and_i_confirm_archiving_the_provider(provider_to_confirm = provider)
    and_i_am_taken_to("/providers/#{provider_to_confirm.id}/archive")
    and_i_click_on "Archive provider"
  end

  def and_there_is_a_provider
    provider
  end

  def provider
    @provider ||= create(:provider)
  end

  def and_there_is_a_provider_with_an_accreditation
    provider_with_accreditation
  end

  def provider_with_accreditation
    @provider_with_accreditation ||= create(:provider, :accredited)
  end

  def and_i_archive_the_provider(provider_to_archive = provider_with_accreditation)
    when_i_navigate_to_the_archive_provider_page_for_a_specific_provider(provider_to_archive)
    and_i_confirm_archiving_the_provider(provider_to_archive)
  end

  def when_i_navigate_to_the_provider_accreditations_page
    visit "/providers/#{provider_with_accreditation.id}/accreditations"
  end

  def then_i_should_not_see_accreditation_action_buttons
    expect(page).not_to have_link("Add accreditation")
    expect(page).not_to have_link("Change")
    expect(page).not_to have_link("Delete")
  end
end
