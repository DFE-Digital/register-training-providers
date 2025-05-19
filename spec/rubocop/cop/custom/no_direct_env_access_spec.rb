
require "rubocop"
require "rubocop/rspec/support"

require_relative "../../../../lib/rubocop/cop/custom/no_direct_env_access"

RSpec.describe RuboCop::Cop::Custom::NoDirectEnvAccess, :config do
  include RuboCop::RSpec::ExpectOffense

  let(:config) { RuboCop::Config.new }

  context "with ENV[\"FOO\"]" do
    it "registers an offense and autocorrects" do
      expect_offense(<<~RUBY)
        ENV["SOME_ENVIRONMENT_VARIABLES"]
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Custom/NoDirectEnvAccess: Use the Env wrapper instead of direct ENV access.
      RUBY

      expect_correction(<<~RUBY)
        Env.some_environment_variables
      RUBY
    end
  end

  context "with ENV.fetch(\"FOO\")" do
    it "registers an offense and autocorrects" do
      expect_offense(<<~RUBY)
        ENV.fetch("SOME_ENVIRONMENT_VARIABLES")
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Custom/NoDirectEnvAccess: Use the Env wrapper instead of direct ENV access.
      RUBY

      expect_correction(<<~RUBY)
        Env.some_environment_variables
      RUBY
    end
  end

  context "with ENV.fetch and default" do
    it "autocorrects with the default argument" do
      expect_offense(<<~RUBY)
        ENV.fetch("SOME_ENVIRONMENT_VARIABLES", "dfe-sign-in")
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Custom/NoDirectEnvAccess: Use the Env wrapper instead of direct ENV access.
      RUBY

      expect_correction(<<~RUBY)
        Env.some_environment_variables("dfe-sign-in")
      RUBY
    end
  end

  context "with non-string ENV key" do
    it "registers an offense but does not autocorrect" do
      expect_offense(<<~RUBY)
        ENV[some_var]
        ^^^^^^^^^^^^^ Custom/NoDirectEnvAccess: Use the Env wrapper instead of direct ENV access.
      RUBY

      expect_no_corrections
    end
  end

  context "with unsupported method" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        ENV.key?("SOME_ENVIRONMENT_VARIABLES")
      RUBY
    end
  end
end
