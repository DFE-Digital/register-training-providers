class ErrorsController < ApplicationController
  skip_before_action :authenticate

  def not_found
    check_user_is_authenticated

    Rails.logger.warn(
      event: "not_found",
      user_id: current_user&.id,
      controller: self.class.name,
      action: action_name,
      path: request.path,
    )

    render "not_found", status: :not_found
  end

  def unprocessable_entity
    Rails.logger.warn(
      event: "unprocessable_entity",
      user_id: current_user&.id,
      controller: self.class.name,
      action: action_name,
      path: request.path,
    )

    render "unprocessable_entity", status: :unprocessable_content
  end

  def internal_server_error
    Rails.logger.warn(
      event: "internal_server_error",
      user_id: current_user&.id,
      controller: self.class.name,
      action: action_name,
      path: request.path,
    )

    render "internal_server_error", status: :internal_server_error
  end

private

  def check_user_is_authenticated
    nil if authenticated?
  end
end
