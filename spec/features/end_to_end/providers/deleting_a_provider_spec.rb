RSpec.feature "Delete Provider" do
  scenario "User can delete a provider" do
    given_i_am_an_authenticated_user
    and_there_is_a_provider
    when_i_navigate_to_the_delete_provider_page_for_a_specific_provider
    and_i_confirm_archiving_the_provider
    then_i_should_be_redirected_to_the_providers_page
    and_i_should_see_a_success_message
  end

  def and_i_should_see_a_success_message
    expect(page).to have_notification_banner("Success", "Provider deleted")
  end

  def then_i_should_be_redirected_to_the_providers_page
    and_i_am_taken_to("/providers")
  end

  def and_i_should_see_the_archive_status
    expect(page).to have_css(".govuk-tag__heading", text: "Archived")
    expect(page).to have_link("Restore provider", href: provider_restore_path(provider))
    expect(page).to have_link("Delete provider", href: provider_delete_path(provider))
  end

  def when_i_navigate_to_the_delete_provider_page_for_a_specific_provider
    visit "/providers"
    and_i_do_not_see_link provider.operating_name
    and_i_check "Include archived providers"
    click_on "Apply filters"

    click_on provider.operating_name
    and_i_am_taken_to("/providers/#{provider.id}")
    and_i_should_see_the_archive_status
    and_i_click_on "Delete provider"
  end

  def and_i_confirm_archiving_the_provider
    and_i_am_taken_to("/providers/#{provider.id}/delete")
    and_i_click_on "Delete provider"
  end

  def and_there_is_a_provider
    provider
  end

  def provider
    @provider ||= create(:provider, :archived)
  end

  def and_i_do_not_see_link(operating_name)
    expect(page).not_to have_link(operating_name)
  end

  alias_method :and_i_check, :check
end
