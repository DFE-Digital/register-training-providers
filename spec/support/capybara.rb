# NOTE: Used for mainly for screenshot
Capybara.asset_host = "http://localhost:#{ENV.fetch("PORT", 1025)}"
Capybara.save_path = "tmp/screenshots/"

# --no-sandbox is required in CI, where Chrome runs as root in the workflow
# container without the user namespace it needs to sandbox itself.
Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--window-size=1400,1600")
  options.binary = ENV["CHROME_BIN"] if ENV["CHROME_BIN"].present?

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.javascript_driver = :headless_chrome

Capybara::Screenshot.prune_strategy = :keep_last_run

timestamp = Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")

Capybara::Screenshot.register_filename_prefix_formatter(:rspec) do |example|
  description = example.full_description
                       .downcase
                       .gsub(/\s+/, "-") # spaces → dashes
                       .gsub(/["<>|:*?\\\/\r\n]/, "") # remove invalid characters
                       .gsub(/[^a-z0-9\-_]/, "") # strip anything not a-z, 0-9, -, _

  "#{description}_#{timestamp}"
end

Capybara::Screenshot::RSpec::REPORTERS["RSpec::Core::Formatters::HtmlFormatter"] = Capybara::Screenshot::RSpec::HtmlEmbedReporter
