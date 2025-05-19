module Env
  def self.logger
    defined?(Rails) ? Rails.logger : Logger.new($stdout)
  end

  def self.method_missing(name, *args)
    key = name.to_s.upcase
    default = args.first

    if ENV.key?(key)
      ENV.fetch(key)
    else
      logger.warn("[Env] ENV['#{key}'] is missing")
      default
    end
  end

  def self.respond_to_missing?(_name, _include_private = false)
    true
  end
end
