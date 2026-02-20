module HttpBasicAuth
  extend ActiveSupport::Concern

  included do
    before_action :enforce_basic_auth,
                  if: -> { BasicAuthenticable.required? }
  end

private

  def enforce_basic_auth
    authenticate_or_request_with_http_basic do |u, p|
      BasicAuthenticable.authenticate(u, p)
    end
  end
end
