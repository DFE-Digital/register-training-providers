class ErrorsController < ApplicationController
  skip_before_action :authenticate

  def not_found
    check_user_is_authenticated
    render "not_found", status: :not_found
  end

  def unprocessable_entity
    render "unprocessable_entity", status: :unprocessable_entity
  end

  def internal_server_error
    render "internal_server_error", status: :internal_server_error
  end

private

  def check_user_is_authenticated
    nil if authenticated?
  end
end
