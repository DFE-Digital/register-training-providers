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
      expect(logger).to have_received(:warn).with("[Env] ENV['SOME_ENVIRONMENT_VARIABLES'] is missing")
    end
  end

  describe ".respond_to_missing?" do
    it "returns true for any method" do
      expect(Env.respond_to?(:anything)).to be true
    end
  end
end
