class LandingPageController < ApplicationController
  skip_before_action :authenticate
  skip_after_action :verify_pundit_authorization

  def start
    if authenticated?
      redirect_to landing_page_path
    end
  end
end
