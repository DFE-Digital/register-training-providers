# spec/support/failure_capture.rb
require_relative "failure_artifacts"
require_relative "capybara_screenshot_silencer"
require_relative "failure_notification"

RSpec.configure do |config|
  config.before(:each) do |example|
    example.metadata[:test_started_at] = Time.current
  end

  # Capture the exact time the test finishes and trigger dumps on failure
  config.after(:each) do |example|
    example.metadata[:test_finished_at] = Time.current

    next unless example.exception

    example.metadata[:db_dump_path] = FailureArtifacts.capture(example)
  end
end
