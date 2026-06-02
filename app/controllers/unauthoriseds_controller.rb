class UnauthorisedsController < ApplicationController
  skip_before_action :check_user_is_active

  def show
  end
end
