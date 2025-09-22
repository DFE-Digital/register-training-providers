class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :touch_session

  before_action :authenticate

  helper_method :current_user, :authenticated?, :provider

  before_action :enforce_basic_auth, if: -> { BasicAuthenticable.required? }

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

private

  def enforce_basic_auth
    authenticate_or_request_with_http_basic do |username, password|
      BasicAuthenticable.authenticate(username, password)
    end
  end

  # dfe and otp objects can both be instantiated as `.begin_session!` will always create
  # a session with a dfe/otp_sign_in_user hash regardless of there being a user/email.
  # We only want to memoize the instance that responds to #user hence the `.select`
  def sign_in_user
    @sign_in_user ||= [
      DfESignInUser.load_from_session(session),
    ].find { |x| x.try(:user) }
  end

  def current_user
    @current_user ||= sign_in_user&.user
  end

  def provider
    @provider ||= policy_scope(Provider).find(params[:provider_id])
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

  def touch_session
    # This changes the session to force cookie renewal
    session[:last_seen_at] = Time.current
  end
end
