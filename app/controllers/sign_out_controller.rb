class SignOutController < ApplicationController
  def index
    DfESignInUser.end_session!(session)
    redirect_to(sign_in_user.logout_url(request), allow_other_host: true)
  end
end
