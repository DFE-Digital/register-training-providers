module AuthenticationHelper
  def given_i_am_authenticated(user: nil)
    @current_user = user if user.present?
    user_exists_in_dfe_sign_in(user: current_user)

    and_i_visit_the_sign_in_page
  end

  def given_i_am_an_authenticated_user
    given_i_am_authenticated
  end

  def and_i_visit_the_sign_in_page
    visit "/sign-in"
    and_i_click_on("Sign in using DfE Sign-in")
  end

  def and_i_have_a_dfe_sign_in_account
    user_exists_in_dfe_sign_in(user: @current_user)
  end

  def current_user
    @current_user ||= create(:user)
  end

  def and_i_am_registered_as_a_user
    current_user
  end
end
