class Users::DeletesController < CheckController
  def show
    @user = User.find(params[:user_id])
    authorize @user
  end

  def destroy
    @user = User.find(params[:user_id])
    authorize @user
    @user.discard!
    redirect_to(users_path, flash: { success: "User deleted" })
  end
end
