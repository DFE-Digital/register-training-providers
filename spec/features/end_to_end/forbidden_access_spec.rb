require "rails_helper"

RSpec.feature "Forbidden access" do
  scenario "for an api user accessing providers listing" do
    given_i_am_on_the_start_page
    and_i_am_not_signed_in
    and_there_is_no_sign_out_link
    and_i_am_registered_as_an_api_user
    and_i_have_a_dfe_sign_in_account_and_am_an_api_user
    and_i_sign_in_via_dfe_sign_in

    and_i_am_redirected_to_the_providers_page
    and_i_click_on("Your account")
    and_i_go_to_the_account_page
    and_i_click_on("Register of training providers")
    and_i_am_taken_to("/providers")

    when_i_visit("/providers")
    then_i_am_taken_to_the_providers_page
    when_i_click_on("Sign out")
    then_i_logout_via_sso
    and_i_am_taken_to("/")
    and_i_am_not_signed_in
  end

  scenario "for an api user attempting to change a provider" do
    given_i_am_an_authenticated_api_user
    and_there_is_a_provider

    expect(Rails.logger).to receive(:warn).with(
      event: "authorization_denied",
      user_id: current_api_user.id,
      controller: "Providers::ProviderChangesController",
      action: "new",
      path: provider_change_step_path(provider_id: provider.id, field: "operating_name", step: "effective-date"),
      policy: "ProviderPolicy",
      query: :update?,
    )

    when_i_visit(provider_change_step_path(provider_id: provider.id, field: "operating_name", step: "effective-date"))

    then_i_am_taken_shown_the_forbidden_page
  end

  def given_i_am_on_the_start_page
    visit "/"
  end

  def and_i_sign_in_via_dfe_sign_in
    and_i_visit_the_sign_in_page
  end

  def and_i_go_to_the_account_page
    expect(page).to have_current_path("/account")
  end

  def and_i_am_redirected_to_the_providers_page
    expect(page).to have_current_path("/providers")
  end

  def then_i_am_taken_to_the_providers_page
    expect(page).to have_current_path("/providers")
    expect(page.status_code).to eq(200)
  end

  def when_i_visit(path)
    visit path
  end

  def and_there_is_a_provider
    provider
  end

  def provider
    @provider ||= create(:provider)
  end

  def then_i_am_taken_shown_the_forbidden_page
    expect(page).to have_current_path(provider_change_step_path(provider_id: provider.id, field: "operating_name", step: "effective-date"))
    expect(page.status_code).to eq(403)
    expect(page).to have_content("You do not have permission to perform this action")
    expect(page).to have_title("You do not have permission to perform this action")
  end

  def then_i_logout_via_sso
    # NOTE: 1, signs out via external sso
    expect(current_url).to start_with("https://test-oidc.signin.education.gov.uk/session/end")
    uri = URI.parse(current_url)
    query = CGI.parse(uri.query)
    expect(uri.path).to eq("/session/end")

    # NOTE: 2, used the configured signout link
    sign_out_link = "http://www.example.com/auth/dfe/sign-out"
    expect(query["post_logout_redirect_uri"].first).to eq(sign_out_link)

    # NOTE: 3, hand-off visit our sign out link afterwards
    visit sign_out_link
  end

  def and_i_am_not_signed_in
    expect(page).to have_link("Sign in")
    and_there_is_no_sign_out_link
  end

  def and_there_is_no_sign_out_link
    expect(page).not_to have_link("Sign out")
  end
end
