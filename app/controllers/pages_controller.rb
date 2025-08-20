class PagesController < ApplicationController
  skip_before_action :authenticate

  def cookies
  end

  def accessibility
  end

  def privacy
  end
end
