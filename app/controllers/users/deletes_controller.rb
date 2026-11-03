class Users::DeletesController < CheckController
  rate_limit to: 3, within: 3.minutes, only: :destroy, by: -> { current_user.id }

  def show
    @user = User.find(params[:user_id])
    authorize @user, :destroy?
  end

  def destroy
    @user = User.find(params[:user_id])
    authorize @user

    User.transaction do
      User.active_reg.lock.load
      @user.lock!
      User.ensure_minimum_active_users!(users_id_to_exclude: @user.id)
      if @user.role == UserRoleEnum::REG && @user.active?
        User.ensure_minimum_reg_users!(users_id_to_exclude: @user.id)
      end

      @user.discard!
    end
    redirect_to(users_path, flash: { success: "User deleted" })
  end
end
