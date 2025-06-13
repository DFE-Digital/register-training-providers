class SignInController < ApplicationController
  skip_before_action :authenticate

  def index
    sign_in_method
  end

private

  def sign_in_method
    @sign_in_method ||= Env.sign_in_method("dfe-sign-in")
  end
end
