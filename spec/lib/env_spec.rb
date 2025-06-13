RSpec.describe Env do
  let(:logger) { instance_double(Logger, warn: nil) }

  before do
    allow(Env).to receive(:logger).and_return(logger)
  end

  context "when ENV key exists" do
    before do
      ENV["SOME_ENVIRONMENT_VARIABLES"] = "env-value"
    end

    after do
      ENV.delete("SOME_ENVIRONMENT_VARIABLES")
    end

    it "returns the ENV value ignoring default" do
      expect(Env.some_environment_variables("default-value")).to eq("env-value")
    end

    it "does not log a warning" do
      Env.some_environment_variables("default-value")
      expect(logger).not_to have_received(:warn)
    end
  end

  context "when ENV key does not exist" do
    before do
      ENV.delete("SOME_ENVIRONMENT_VARIABLES")
    end

    it "returns the default value" do
      expect(Env.some_environment_variables("default-value")).to eq("default-value")
    end

    it "logs a warning" do
      Env.some_environment_variables("default-value")
      expect(logger).to have_received(:warn).with(
        "[Env.some_environment_variables] ENV['SOME_ENVIRONMENT_VARIABLES'] is missing"
      )
    end
  end

  describe ".respond_to_missing?" do
    it "returns true for any method" do
      expect(Env.respond_to?(:anything)).to be true
    end
  end

  describe "boolean accessor via method_missing" do
    after { ENV.delete("SOME_FEATURE") }

    context "when ENV[SOME_FEATURE] is set to a truthy value" do
      ["true", "1", "yes", "on"].each do |truthy|
        it "returns true for #{truthy.inspect}" do
          ENV["SOME_FEATURE"] = truthy
          expect(Env.some_feature?).to be true
        end
      end
    end

    context "when ENV[SOME_FEATURE] is set to a falsey value" do
      ["false", "0", "no", "off", "", nil].each do |falsey|
        it "returns false for #{falsey.inspect}" do
          ENV["SOME_FEATURE"] = falsey unless falsey.nil?
          expect(Env.some_feature?).to be false
        end
      end
    end

    context "when ENV[SOME_FEATURE] is missing" do
      it "returns false by default" do
        expect(Env.some_feature?).to be false
      end

      it "returns the fallback if given" do
        expect(Env.some_feature?(true)).to be true
      end

      it "logs a warning" do
        Env.some_feature?
        expect(logger).to have_received(:warn).with("[Env.some_feature?] ENV['SOME_FEATURE'] is missing")
      end
    end
  end
end
