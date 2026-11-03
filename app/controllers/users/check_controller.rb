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
    lock_active_regs if active_reg_set_can_change?
    lock_model_and_refresh_changes
    ensure_minimum_active_users_would_hold!
    ensure_minimum_reg_users_would_hold!
  end

private

  def save
    authorize model

    return redirect_to back_path unless staged_record?

    User.transaction do
      super
    end
  end

  def staged_record?
    return true if model_id.nil?

    draft = current_user.temporary_records.find_by(record_type: "User", purpose: purpose)

    draft.present? && !draft.expired?
  end

  def active_reg_set_can_change?
    model.persisted? && model.changes.keys.intersect?(%w[role active api_user])
  end

  def lock_active_regs
    User.active_reg.lock.load
  end

  def lock_model_and_refresh_changes
    return unless model.persisted?

    staged_changes = model.changes.except("created_at", "updated_at").transform_values(&:last)
    model.reload(lock: true)
    model.assign_attributes(staged_changes)
  end

  def ensure_minimum_active_users_would_hold!
    return unless model.persisted?
    return unless model.changes.keys.intersect?(%w[active api_user])
    return if model.active? && !model.api_user?

    User.ensure_minimum_active_users!(users_id_to_exclude: model.id)
  end

  def ensure_minimum_reg_users_would_hold!
    return unless model.persisted?
    return unless model.role_was == UserRoleEnum::REG && model.active_was
    return if model.role == UserRoleEnum::REG && model.active? && !model.api_user?

    User.ensure_minimum_reg_users!(users_id_to_exclude: model.id)
  end

  def purpose
    User.temporary_purpose(model_id)
  end
end
