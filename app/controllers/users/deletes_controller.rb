class Users::DeletesController < CheckController
  def show
    @user = User.find(params[:user_id])
  end
end
