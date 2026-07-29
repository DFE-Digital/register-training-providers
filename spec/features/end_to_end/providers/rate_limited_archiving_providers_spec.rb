RSpec.feature "Archive Provider" do
  scenario "rate limited of a user archiving providers" do
    given_i_am_an_authenticated_user
    and_i_have_providers_to_archive
    and_i_am_on_the_provider_listing_page

    and_i_can_see_the_page_title_providers_with_the_count(count: 4)

    Timecop.freeze(Time.zone.now) do
      providers_to_archive.each do |provider_to_archive|
        and_i_click_on(provider_to_archive.operating_name)
        and_i_am_taken_to("/providers/#{provider_to_archive.id}")

        and_i_click_on("Archive provider")
        and_i_am_taken_to("/providers/#{provider_to_archive.id}/archive")

        when_i_click_on("Archive provider")
        then_i_see_the_success_message
        and_i_am_taken_to("/providers/#{provider_to_archive.id}")
        when_i_click_on("Back")
        and_i_am_taken_to("/providers")
      end

      and_i_can_see_the_page_title_providers_with_the_count(count: 1)
      and_i_check "Include archived providers"
      and_i_click_on "Apply filters"
      and_i_can_see_the_page_title_providers_with_the_count(count: 4)

      and_i_click_on(provider_fails_to_be_archived.operating_name)
      and_i_am_taken_to("/providers/#{provider_fails_to_be_archived.id}")

      and_i_click_on("Archive provider")
      and_i_am_taken_to("/providers/#{provider_fails_to_be_archived.id}/archive")

      expect(Rails.logger).to receive(:warn).with(
        event: "too_many_requests",
        user_id: current_user.id,
        controller: "Providers::ArchivesController",
        action: "update",
        path: "/providers/#{provider_fails_to_be_archived.id}/archive",
      )

      when_i_click_on("Archive provider")
      and_i_can_see_the_page_title_for_not_able_to_complete_this_action
      and_i_am_still_on("/providers/#{provider_fails_to_be_archived.id}/archive")
    end
  end

  def and_i_can_see_the_page_title_for_not_able_to_complete_this_action
    expect(page).to have_title("Sorry, there’s a problem completing this action - Register of training providers - GOV.UK")
  end

  def and_i_can_see_the_page_title_providers_with_the_count(count: 1)
    expect(page).to have_title("Providers (#{count}) - Register of training providers - GOV.UK")
  end

  def and_i_am_on_the_provider_listing_page
    visit "/providers"
  end

  def and_i_have_providers_to_archive
    providers_to_archive
    provider_fails_to_be_archived
  end

  def providers_to_archive
    @providers_to_archive ||= create_list(:provider, 3)
  end

  def provider_fails_to_be_archived
    @provider_fails_to_be_archived ||= create(:provider)
  end

  def then_i_see_the_success_message
    expect(page).to have_notification_banner("Success", "Provider archived")
  end

  alias_method :and_i_check, :check
end
