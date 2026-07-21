module SilentScreenshotReporter
end

if defined?(Capybara::Screenshot::RSpec::REPORTERS)
  Capybara::Screenshot::RSpec::REPORTERS["RSpec::Core::Formatters::ProgressFormatter"] = SilentScreenshotReporter
  Capybara::Screenshot::RSpec::REPORTERS["RSpec::Core::Formatters::DocumentationFormatter"] = SilentScreenshotReporter
end
