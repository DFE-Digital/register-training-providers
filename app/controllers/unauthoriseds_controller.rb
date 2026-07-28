class UnauthorisedsController < ApplicationController
  skip_before_action :check_user_is_active
  skip_after_action :verify_pundit_authorization

  def show
  end
end
