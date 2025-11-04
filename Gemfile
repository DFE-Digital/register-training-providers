source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.1"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.6"
gem "pg_search"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]
gem "jsbundling-rails"
# Bundle and process CSS [https://github.com/rails/cssbundling-rails]
gem "cssbundling-rails"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Govuk design system
gem "govuk-components"
gem "govuk_design_system_formbuilder"
gem "govuk_markdown"

# Shim to load environment variables from .env into ENV
gem "dotenv-rails"

# Logs all changes to the models.
gem "audited"

gem "rails_semantic_logger"

# Soft deletes for ActiveRecord done right.
gem "discard", "~> 1.4"

# UK postcode parsing and validation
gem "uk_postcode"

# DfE Sign-in
gem "omniauth"
gem "omniauth_openid_connect"
gem "omniauth-rails_csrf_protection"

# Pagination
gem "pagy", "~> 9.4" # omit patch digit

# Sentry
gem "sentry-rails"
gem "sentry-ruby"
gem "stackprof"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri windows]

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  gem "rspec"
  gem "rspec-rails"

  gem "capybara-screenshot"
end

group :development do
  gem "rladr"
  gem "solargraph", require: false
  gem "solargraph-rails", require: false
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add a comment summarising the current schema to each Active Record
  gem "annotaterb"

  # Generates entity-relationship diagram based on the Active Records.
  gem "rails-erd"

  gem "erb_lint"
  gem "prettier_print", require: false

  gem "rubocop", require: false
  gem "rubocop-govuk", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rails", require: false

  gem "syntax_tree", require: false
  gem "syntax_tree-rbs", require: false

  gem "database_consistency", require: false
end

group :development, :review, :test, :qa do
  # Rails integration for https://github.com/thoughtbot/factory_bot
  gem "factory_bot_rails"

  # A library for generating fake data such as names, addresses, and phone numbers.
  gem "faker"

  gem "csv"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"

  #  Simple one-liner tests for common Rails functionality
  gem "shoulda-matchers"
end

group :development, :production do
  gem "amazing_print"
end

gem "pundit", "~> 2.5"
