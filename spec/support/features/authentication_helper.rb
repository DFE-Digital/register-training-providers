module AuthenticationHelper
  def given_i_am_authenticated(user: nil, api_user: false, inactive_user: false)
    if api_user
      @current_api_user = user if user.present?
      user_exists_in_dfe_sign_in(user: current_api_user)
    elsif inactive_user
      @current_inactive_user = user if user.present?
      user_exists_in_dfe_sign_in(user: current_inactive_user)
    else
      @current_user = user if user.present?
      user_exists_in_dfe_sign_in(user: current_user)
    end

    and_i_visit_the_sign_in_page
  end

  def given_i_am_an_authenticated_user
    given_i_am_authenticated
  end

  def given_i_am_an_authenticated_api_user
    given_i_am_authenticated(api_user: true)
  end

  def given_i_am_an_authenticated_inactive_user
    given_i_am_authenticated(inactive_user: true)
  end

  def and_i_visit_the_sign_in_page
    visit "/sign-in"
    and_i_click_on("Sign in using DfE Sign-in")
  end

  def and_i_have_a_dfe_sign_in_account
    user_exists_in_dfe_sign_in(user: @current_user)
  end

  def and_i_have_a_dfe_sign_in_account_and_am_an_api_user
    user_exists_in_dfe_sign_in(user: @current_api_user)
  end

  def and_i_have_a_dfe_sign_in_account_and_am_an_inactive_user
    user_exists_in_dfe_sign_in(user: @current_inactive_user)
  end

  def current_user
    @current_user ||= create(:user)
  end

  def current_api_user
    @current_api_user ||= create(:user, api_user: true)
  end

  def current_inactive_user
    @current_inactive_user ||= create(:user, active: false)
  end

  def and_i_am_registered_as_a_user
    current_user
  end

  def and_i_am_registered_as_an_api_user
    current_api_user
  end

  def and_i_am_registered_as_an_inactive_user
    current_inactive_user
  end
end
