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

  def pre_save
    if model.changes["active"] == [true, false]

      User.ensure_minimum_active_users!(users_id_to_exclude: model.id)

    end
  end
end
