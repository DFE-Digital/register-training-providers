class SignInController < ApplicationController
  skip_before_action :authenticate
  skip_before_action :check_user_is_active
  skip_after_action :verify_pundit_authorization

  def index
    sign_in_method
  end

private

  def sign_in_method
    @sign_in_method ||= Env.sign_in_method("dfe-sign-in")
  end
end
