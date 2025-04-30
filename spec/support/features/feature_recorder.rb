return if ENV['SELENIUM_DRIVER'].nil?

require 'capybara/rspec'
require 'selenium-webdriver'
require 'screen-recorder'
require 'webdrivers'

Capybara.register_driver :selenium_chrome_recorded do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  # options.add_argument('--headless') unless ENV['DISPLAY']
  options.add_argument('--window-size=1920,1080')  # Example: 1920x1080
  Capybara::Selenium::Driver.new(app,
    browser: :chrome,
    options: options
  )
end

Capybara.configure do |config|
  config.default_driver = ENV['SELENIUM_DRIVER'] == 'chrome' ? :selenium_chrome_recorded : :rack_test
  Capybara.javascript_driver = :selenium_chrome_recorded
end

RSpec.configure do |config|
  config.before(:each, type: :feature) do |example|
    file_name = "tmp/feature_videos/#{example.metadata[:full_description].parameterize}.webm"
    FileUtils.mkdir_p(File.dirname(file_name))

    if ENV['RECORD_FEATURE_TESTS'] == 'true'
      @recorder = ScreenRecorder::Desktop.new(
        output: file_name,
        input: ':99.0'
      )
      @recorder.start
    end
  end

  config.after(:each, type: :feature) do
    if ENV['RECORD_FEATURE_TESTS'] == 'true'
      if defined?(@recorder) && @recorder
        @recorder.stop
        @recorder = nil
      end
    end
  end
end
