class ApplicationController < ActionController::Base
  before_action :authenticate

  helper_method :current_user, :authenticated?

  default_form_builder(GOVUKDesignSystemFormBuilder::FormBuilder)
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private
  # dfe and otp objects can both be instantiated as `.begin_session!` will always create
  # a session with a dfe/otp_sign_in_user hash regardless of there being a user/email.
  # We only want to memoize the instance that responds to #user hence the `.select`
  def sign_in_user
    @sign_in_user ||= [
      DfESignInUser.load_from_session(session),
    ].select { |x| x.try(:user) }.first
  end

  def current_user
    @current_user ||= sign_in_user&.user
  end

  def authenticated?
    current_user.present?
  end

  def save_requested_path
    session[:requested_path] = request.fullpath
  end

  def save_requested_path_and_redirect
    save_requested_path
    redirect_to(sign_in_path)
  end

  def authenticate
    save_requested_path_and_redirect unless authenticated?
  end
end
