class UsersController < ApplicationController
  include Pagy::Backend

  def index
    @pagy, @records = pagy(User.kept.order_by_first_then_last_name)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(params.expect(user: [:first_name, :last_name, :email]))
    if @user.valid?
      redirect_to new_user_check_path
    else
      render(:new)
    end
  end
end
