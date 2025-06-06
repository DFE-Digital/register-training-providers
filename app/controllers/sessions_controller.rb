class SessionsController < ApplicationController
  skip_before_action :authenticate

  def callback
    DfESignInUser.begin_session!(session, request.env["omniauth.auth"])

    if current_user
      DfESignInUsers::Update.call(user: current_user, sign_in_user: sign_in_user)

      redirect_to(login_redirect_path)
    else
      session.delete(:requested_path)
      DfESignInUser.end_session!(session)
      redirect_to(sign_in_user_not_found_path)
    end
  end

  def signout
    redirect_to(root_path)
  end

private

  def login_redirect_path
    session.delete(:requested_path) || providers_path
  end
end
