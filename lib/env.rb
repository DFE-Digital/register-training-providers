module Env
  def self.logger
    defined?(Rails) ? Rails.logger : Logger.new($stdout)
  end

  def self.method_missing(name, *args)
    method = name.to_s
    fallback = args.first

    key = env_key(method)
    val = ENV.fetch(key, nil)

    if boolean_method?(method)
      return interpret_bool(val) unless val.nil?

      logger.warn("[Env.#{method}] ENV['#{key}'] is missing")
      return fallback.nil? ? false : fallback
    end

    if ENV.key?(key)
      val
    else
      logger.warn("[Env.#{method}] ENV['#{key}'] is missing")
      fallback
    end
  end

  def self.respond_to_missing?(_name, _include_private = false)
    true
  end

  private_class_method def self.boolean_method?(method)
    method.end_with?("?")
  end

  private_class_method def self.env_key(method)
    method.chomp("?").upcase
  end

  # NOTE: It interprets a string as a boolean not interprets as a simple true or false
  private_class_method def self.interpret_bool(val)
    case val.to_s.strip.downcase
    when "true", "1", "yes", "on" then true
    when "false", "0", "no", "off", "" then false
    end
  end
end
