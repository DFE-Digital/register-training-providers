class UsersController < ApplicationController
  include Pagy::Backend

  def index
    current_user.clear_temporary_records(User)
    authorize User

    @pagy, @records = pagy(policy_scope(scoped_user.order_by_first_then_last_name))
    verify_policy_scoped
  end

  def show
    @user = scoped_user.find(user_id)
    authorize @user
  end

  def new
    @user = current_user.load_temporary(scoped_user, purpose: new_user_purpose)
    @user.role ||= UserRoleEnum::REG unless @user.api_user?
    authorize @user
  end

  def edit
    current_user.clear_temporary(User, purpose: user_purpose) if params[:goto] != "confirm"
    @user = current_user.load_temporary(scoped_user, id: user_id, purpose: user_purpose)
    authorize @user
  end

  def create
    @user = scoped_user.new(params.expect(user: user_params))
    authorize @user

    if @user.valid?
      @user.save_as_temporary!(created_by: current_user, purpose: new_user_purpose)
      redirect_to new_user_confirm_path
    else
      render(:new)
    end
  end

  def update
    @user = current_user.load_temporary(scoped_user, id: user_id, purpose: user_purpose)
    authorize @user

    @user.assign_attributes(params.expect(user: user_params))

    if @user.valid?
      @user.save_as_temporary!(created_by: current_user, purpose: user_purpose)
      redirect_to user_check_path(@user)
    else
      render(:edit)
    end
  end

private

  def user_id
    params[:id]
  end

  def scoped_user
    @scoped_user || policy_scope(User)
  end

  def new_user_purpose
    User.temporary_purpose
  end

  def user_purpose
    User.temporary_purpose(user_id)
  end

  def user_params
    permitted = if @user.nil?
                  [:first_name, :last_name, :email, :api_user]
                elsif @user.last_signed_in_at.nil?
                  [:first_name, :last_name, :email, :api_user, :active]
                else
                  [:api_user, :active]
                end
    permitted << :role if current_user.reg?
    permitted
  end
end
