class UsersController < ApplicationController
  include Pagy::Backend

  def index
    current_user.clear_temporary(User, purpose: :check_your_answers)

    @pagy, @records = pagy(User.kept.order_by_first_then_last_name)
  end

  def show
    @user = User.find(id)
  end

  def new
    @user = current_user.load_temporary(User, purpose: :check_your_answers)
  end

  def edit
    @user = current_user.load_temporary(User, id: id, purpose: :check_your_answers)
  end

  def create
    @user = User.new(params.expect(user: [:first_name, :last_name, :email]))
    if @user.valid?
      @user.save_as_temporary!(created_by: current_user, purpose: :check_your_answers)
      redirect_to new_user_confirm_path
    else
      render(:new)
    end
  end

  def update
    @user = current_user.load_temporary(User, id: id, purpose: :check_your_answers)

    @user.assign_attributes(params.expect(user: [:first_name, :last_name, :email]))

    if @user.valid?
      @user.save_as_temporary!(created_by: current_user, purpose: :check_your_answers)
      redirect_to user_check_path(@user)
    else
      render(:edit)
    end
  end

  def id
    params[:id].to_i
  end
end
