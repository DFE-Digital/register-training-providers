require "rails_helper"

RSpec.describe "Deleting accreditation", type: :feature do
  before do
    given_i_am_an_authenticated_user
  end

  scenario "User can delete an accreditation" do
    given_there_is_a_provider_with_an_accreditation
    and_i_navigate_to_the_provider_page
    when_i_click_delete_on_the_accreditation
    and_i_confirm_removing_the_accreditation
    then_i_should_be_redirected_to_the_accreditations_page
    and_i_should_see_a_success_message
    and_the_accreditation_should_be_deleted
  end

  scenario "User can cancel deleting an accreditation" do
    given_there_is_a_provider_with_an_accreditation
    and_i_navigate_to_the_delete_accreditation_page
    when_i_click_cancel
    then_i_should_be_redirected_to_the_accreditations_page
    and_the_accreditation_should_still_exist
  end

private

  def given_there_is_a_provider_with_an_accreditation
    provider
    accreditation
  end

  def and_i_navigate_to_the_provider_page
    visit provider_accreditations_path(provider)
  end

  def and_i_navigate_to_the_delete_accreditation_page
    visit accreditation_delete_path(accreditation, provider_id: provider.id)
  end

  def when_i_click_delete_on_the_accreditation
    within(".govuk-summary-card", text: "Accreditation #{accreditation.number}") do
      click_link "Delete"
    end
  end

  def and_i_confirm_removing_the_accreditation
    expect(page).to have_content("Confirm you want to delete #{provider.operating_name}’s accreditation")
    expect(page).to have_content("Accreditation number")
    expect(page).to have_content(accreditation.number)

    click_button "Delete accreditation"
  end

  def when_i_click_cancel
    click_link "Cancel"
  end

  def then_i_should_be_redirected_to_the_accreditations_page
    expect(page).to have_current_path(provider_accreditations_path(provider))
  end

  def and_i_should_see_a_success_message
    expect(page).to have_notification_banner("Success", "Accreditation deleted")
  end

  def and_the_accreditation_should_be_deleted
    expect(accreditation.reload).to be_discarded
  end

  def and_the_accreditation_should_still_exist
    expect(accreditation.reload).not_to be_discarded
  end

  def provider
    @provider ||= create(:provider, :accredited)
  end

  def accreditation
    @accreditation ||= create(:accreditation, :current, provider:)
  end
end
