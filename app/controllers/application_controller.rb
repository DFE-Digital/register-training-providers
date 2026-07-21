class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include HttpBasicAuth

  before_action :touch_session

  before_action :authenticate

  before_action :check_user_is_active

  helper_method :current_user, :authenticated?, :provider, :active_user?

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  rescue_from Pundit::NotAuthorizedError do |exception|
    Rails.logger.warn(
      event: "authorization_denied",
      user_id: current_user&.id,
      controller: self.class.name,
      action: action_name,
      path: request.path,
      policy: exception.policy.class.name,
      query: exception.query,
    )
    render "errors/forbidden", status: :forbidden, formats: [:html]
  end

private

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

  def inactive_user?
    authenticated? && !current_user&.active?
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

  def check_user_is_active
    redirect_to unauthorised_path if inactive_user?
  end

  def touch_session
    # This changes the session to force cookie renewal
    session[:last_seen_at] = Time.current
  end

  def landing_page_path
    return api_clients_path if current_user.api_user?

    providers_path
  end
end
