class Users::DeletesController < CheckController
  def show
    @user = User.find_by(uuid: params[:user_id])
  end

  def destroy
    @user = User.find_by(uuid: params[:user_id])
    @user.discard!
    redirect_to(users_path, flash: { success: "Support user deleted" })
  end
end
