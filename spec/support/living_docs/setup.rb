return unless ENV.fetch("LIVING_DOCS", nil) == "1"

require "capybara/playwright"
require_relative "helpers"
require_relative "capybara_extensions"

# Apply Capybara extensions
Capybara::Node::Element.prepend(HighlightAndPauseClick)
Capybara::Session.prepend(AutoIntroCard)

# Register custom driver
Capybara.register_driver(:playwright_video) do |app|
  Capybara::Playwright::Driver.new(
    app,
    browser_type: :chromium,
    headless: true,
    viewport: { width: 2560, height: 1440 },
    args: ["--window-size=2560,1440"],
    record_video_dir: "tmp/videos",
    record_video_size: { width: 2560, height: 1440 }
  )
end

# Hook into RSpec lifecycle
RSpec.configure do |config|
  config.before(:suite) do
    WebMock.disable_net_connect!(allow_localhost: true) if defined?(WebMock)
    FileUtils.mkdir_p("tmp/videos")
  end

  config.before(:example, :living_docs) do |example|
    Capybara.current_driver = :playwright_video
    Capybara.current_session.instance_variable_set(:@intro_shown, false)
    Capybara.current_session.instance_variable_set(:@screenshot_counter, 0)

    Capybara.current_session.driver.on_save_screenrecord do |video_path|
      if video_path && File.exist?(video_path)
        new_path = "#{LivingDocsHelpers.base_dir(example)}/#{File.basename(LivingDocsHelpers.base_dir(example))}.webm"
        FileUtils.mv(video_path, new_path)
        puts "\n🎥 Video saved to: #{new_path}"
      end
    end
  end

  config.after(:example, :living_docs) do |example|
    session = Capybara.current_session

    # Capture final state before resetting
    LivingDocsHelpers.take_screenshot(session, "final_state", example)
    sleep 0.5

    Capybara.reset_sessions!

    # Generate the JSON backing file!
    LivingDocsHelpers.generate_json_data(example)

    Capybara.use_default_driver
  end
end
