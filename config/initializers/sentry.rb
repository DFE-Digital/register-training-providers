IGNORED_PATHS = [
  %r{^/cookies},
  %r{^/accessibility},
  %r{^/privacy},
  %r{^/ping},
  %r{^/healthcheck},
  %r{^/sha}
].freeze

Sentry.init do |config|
  config.dsn = ENV.fetch("SENTRY_DSN", nil)
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  config.send_default_pii = false

  config.enable_logs = !(Rails.env.development? || Rails.env.review?)

  config.enabled_patches = [:logger]

  config.traces_sampler = lambda do |sampling_context|
    transaction_context = sampling_context[:transaction_context]
    op   = transaction_context[:op]
    name = transaction_context[:name].to_s

    case op
    when /request/
      if IGNORED_PATHS.any? { |regex| name.match?(regex) }
        0.0
      else
        0.1
      end
    else
      0.0
    end
  end

  config.profiles_sample_rate = 0.1

  config.release = ENV.fetch("COMMIT_SHA", nil)
  config.environment = Rails.env
end
