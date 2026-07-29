class Users::DeletesController < CheckController
  rate_limit to: 3, within: 3.minutes, only: :destroy, by: -> { current_user.id }

  def show
    @user = User.find(params[:user_id])
  end

  def destroy
    @user = User.find(params[:user_id])
    @user.discard!
    redirect_to(users_path, flash: { success: "User deleted" })
  end
end
