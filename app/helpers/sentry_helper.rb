module SentryHelper
  def sentry_trace_meta
    raw Sentry.get_trace_propagation_meta
  end
end
