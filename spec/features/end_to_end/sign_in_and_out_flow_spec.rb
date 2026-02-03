require "rails_helper"

RSpec.feature "Sign in and_out flow" do
  scenario do
    given_i_am_on_the_start_page
    and_i_am_not_signed_in
    and_there_is_no_sign_out_link
    and_i_am_registered_as_a_user
    and_i_have_a_dfe_sign_in_account
    and_i_sign_in_via_dfe_sign_in

    and_i_am_redirect_to_provider_page
    and_i_click_on("Users")
    and_i_go_to_the_users_page
    and_i_click_on("Register of training providers")
    and_i_am_taken_to("/providers")

    when_i_click_on("Sign out")
    then_i_logout_via_sso
    and_i_am_taken_to("/")
    and_i_am_not_signed_in
  end

  def given_i_am_on_the_start_page
    visit "/"
  end

  def and_i_sign_in_via_dfe_sign_in
    and_i_visit_the_sign_in_page
  end

  def and_i_go_to_the_users_page
    expect(page).to have_current_path("/users")
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

  def and_i_am_redirect_to_provider_page
    expect(page).to have_current_path("/providers")
  end

  def and_there_is_no_sign_out_link
    expect(page).not_to have_link("Sign out")
  end
end
