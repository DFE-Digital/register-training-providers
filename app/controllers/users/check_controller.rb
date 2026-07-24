class Users::CheckController < CheckController
  def post_save
    if model.saved_changes["active"] == [true, false]
      Rails.logger.warn(
        event: "user_deactivated",
        user_id: current_user&.id,
        deactivate_user_id: model.id
      )
    end
  end
end
