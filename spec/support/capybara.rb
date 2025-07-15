# NOTE: Used for mainly for screenshot
Capybara.asset_host = "http://localhost:#{ENV.fetch("PORT", 1025)}"
Capybara.save_path = "tmp/screenshots/"

Capybara::Screenshot.prune_strategy = :keep_last_run

timestamp = Time.zone.now.strftime("%Y-%m-%d-%H-%M-%S")

Capybara::Screenshot.register_filename_prefix_formatter(:rspec) do |example|
  description = example.full_description
                       .downcase
                       .gsub(/\s+/, "-") # spaces → dashes
                       .gsub(/[\"<>|:*?\\\/\r\n]/, "") # remove invalid characters
                       .gsub(/[^a-z0-9\-_]/, "") # strip anything not a-z, 0-9, -, _

  "#{description}_#{timestamp}"
end

Capybara::Screenshot::RSpec::REPORTERS["RSpec::Core::Formatters::HtmlFormatter"] = Capybara::Screenshot::RSpec::HtmlEmbedReporter
