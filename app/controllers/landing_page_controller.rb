class LandingPageController < ApplicationController
  skip_before_action :authenticate

  def start
    if authenticated?
      redirect_to landing_page_path
    end
  end
end
