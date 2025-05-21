class LandingPageController < ApplicationController
  skip_before_action :authenticate

  def start
  end
end
