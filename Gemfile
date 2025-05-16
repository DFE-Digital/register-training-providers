source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.2"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]
gem "jsbundling-rails"
# Bundle and process CSS [https://github.com/rails/cssbundling-rails]
gem "cssbundling-rails"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

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

# Shim to load environment variables from .env into ENV
gem "dotenv-rails"

# Logs all changes to the models.
gem "audited"

gem "rails_semantic_logger"

# Soft deletes for ActiveRecord done right.
gem "discard", "~> 1.4"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ]

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  gem "rspec"
  gem "rspec-rails"
end

group :development do
  gem "rladr"
  gem "solargraph", require: false
  gem "solargraph-rails", require: false
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add a comment summarising the current schema to each Active Record
  gem "annotate"

  # Generates entity-relationship diagram based on the Active Records.
  gem "rails-erd"

  gem 'prettier_print', require: false
  gem 'rubocop-govuk', require: false
  gem 'syntax_tree', require: false
  gem 'syntax_tree-rbs', require: false
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"

  # Rails integration for https://github.com/thoughtbot/factory_bot
  gem "factory_bot_rails"

  # A library for generating fake data such as names, addresses, and phone numbers.
  gem "faker"

  #  Simple one-liner tests for common Rails functionality
  gem "shoulda-matchers"
end

group :development, :production do
  gem "amazing_print"
end
