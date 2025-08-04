class UsersController < ApplicationController
  include Pagy::Backend

  def index
    current_user.clear_temporary(User, purpose: :check_your_answers)

    @pagy, @records = pagy(policy_scope(scoped_user.order_by_first_then_last_name))
  end

  def show
    @user = scoped_user.find_by(uuid:)
    authorize @user
  end

  def new
    @user = current_user.load_temporary(scoped_user, purpose: :check_your_answers)
  end

  def edit
    @user = current_user.load_temporary(scoped_user, uuid: uuid, purpose: :check_your_answers)
  end

  def create
    @user = scoped_user.new(params.expect(user: [:first_name, :last_name, :email]))
    if @user.valid?
      @user.save_as_temporary!(created_by: current_user, purpose: :check_your_answers)
      redirect_to new_user_confirm_path
    else
      render(:new)
    end
  end

  def update
    @user = current_user.load_temporary(scoped_user, uuid: uuid, purpose: :check_your_answers)

    @user.assign_attributes(params.expect(user: [:first_name, :last_name, :email]))

    if @user.valid?
      @user.save_as_temporary!(created_by: current_user, purpose: :check_your_answers)
      redirect_to user_check_path(@user)
    else
      render(:edit)
    end
  end

private

  def uuid
    params[:id]
  end

  def scoped_user
    @scoped_user || policy_scope(User)
  end
end
