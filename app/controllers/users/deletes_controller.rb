class Users::DeletesController < CheckController
  def show
    @user = User.find(params[:user_id])
  end

  def destroy
    @user = User.find(params[:user_id])
    @user.discard!
    redirect_to(users_path, flash: { success: "User deleted" })
  end
end
