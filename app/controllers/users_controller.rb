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
      @user.save!

      redirect_to users_path, flash: { success: "Support user added" }
    else
      render(:new)
    end
  end
end
