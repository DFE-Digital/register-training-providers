class PagesController < ApplicationController
  skip_before_action :authenticate
  skip_after_action :verify_pundit_authorization

  def cookies
  end

  def accessibility
  end

  def privacy
  end
end
