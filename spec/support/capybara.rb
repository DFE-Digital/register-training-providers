# NOTE: Used for mainly for screenshot
Capybara.asset_host = "http://localhost:#{ENV.fetch("PORT", 1025)}"
Capybara.save_path = "tmp/screenshots/"

Capybara::Screenshot.prune_strategy = :keep_last_run
Capybara::Screenshot.register_filename_prefix_formatter(:rspec) do |example|
  example.description.tr(" ", "-").gsub(/^.*\/spec\//, "").to_s
end
Capybara::Screenshot::RSpec::REPORTERS["RSpec::Core::Formatters::HtmlFormatter"] = Capybara::Screenshot::RSpec::HtmlEmbedReporter
