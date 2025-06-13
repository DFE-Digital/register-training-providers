module BasicAuthenticable
  class << self
    def required?
      Env.basic_auth?(false)
    end

    def authenticate(username, password)
      validate(username, password)
    end

    def validate(username, password)
      utils.secure_compare(::Digest::SHA256.hexdigest(auth_username), ::Digest::SHA256.hexdigest(username)) &
        utils.secure_compare(::Digest::SHA256.hexdigest(auth_password), ::Digest::SHA256.hexdigest(password))
    end

    def auth_username
      @auth_username ||= Env.basic_auth_username
    end

    def auth_password
      @auth_password ||= Env.basic_auth_password
    end

    def utils
      ActiveSupport::SecurityUtils
    end
  end
end
