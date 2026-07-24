RSpec.feature "Delete Provider" do
  scenario "rate limited of a user deleting providers" do
    given_i_am_an_authenticated_user
    and_i_have_providers_to_delete

    and_i_am_on_the_provider_listing_page
    and_i_can_see_the_page_title_providers_with_the_count(count: 0)

    and_i_check "Include archived providers"
    and_i_click_on "Apply filters"
    and_i_can_see_the_page_title_providers_with_the_count(count: 4)

    Timecop.freeze(Time.zone.now) do
      providers_to_delete.each do |provider_to_delete|
        and_i_click_on(provider_to_delete.operating_name)
        and_i_am_taken_to("/providers/#{provider_to_delete.id}")

        and_i_click_on("Delete provider")
        and_i_am_taken_to("/providers/#{provider_to_delete.id}/delete")

        when_i_click_on("Delete provider")
        then_i_see_the_success_message
        and_i_am_taken_to("/providers")
        and_i_check "Include archived providers"
        and_i_click_on "Apply filters"
      end

      and_i_can_see_the_page_title_providers_with_the_count(count: 1)

      and_i_click_on(provider_fails_to_be_deleted.operating_name)
      and_i_am_taken_to("/providers/#{provider_fails_to_be_deleted.id}")

      and_i_click_on("Delete provider")
      and_i_am_taken_to("/providers/#{provider_fails_to_be_deleted.id}/delete")

      expect(Rails.logger).to receive(:warn).with(
        event: "too_many_requests",
        user_id: current_user.id,
        controller: "Providers::DeletesController",
        action: "destroy",
        path: "/providers/#{provider_fails_to_be_deleted.id}/delete",
      )

      when_i_click_on("Delete provider")
      and_i_can_see_the_page_title_for_not_able_to_complete_this_action
      and_i_am_still_on("/providers/#{provider_fails_to_be_deleted.id}/delete")
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

  def and_i_have_providers_to_delete
    providers_to_delete
    provider_fails_to_be_deleted
  end

  def providers_to_delete
    @providers_to_delete ||= create_list(:provider, 3, :archived)
  end

  def provider_fails_to_be_deleted
    @provider_fails_to_be_deleted ||= create(:provider, :archived)
  end

  def then_i_see_the_success_message
    expect(page).to have_notification_banner("Success", "Provider deleted")
  end

  alias_method :and_i_check, :check
end
