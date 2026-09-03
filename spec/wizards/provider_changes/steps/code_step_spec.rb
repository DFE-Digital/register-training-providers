require "rails_helper"

RSpec.describe ProviderChanges::Steps::CodeStep do
  subject(:step) { described_class.new(wizard:, code:) }

  let(:wizard) { double(state_store:) }
  let(:state_store) { double(effective_on:) }
  let(:effective_on) { Date.new(2026, 9, 1) }
  let(:code) { "ABC" }

  before do
    allow(ProviderCodeTakenService).to receive(:call).and_return(false)
  end

  describe ".permitted_params" do
    it "permits code" do
      expect(described_class.permitted_params).to eq(%i[code])
    end
  end

  describe "validation" do
    it "accepts a valid three-character code" do
      expect(step).to be_valid
    end

    it "normalises the code to uppercase" do
      step = described_class.new(wizard: wizard, code: "abc")

      expect(step).to be_valid
      expect(step.code).to eq("ABC")
    end

    it "rejects a code that is not three characters" do
      step = described_class.new(wizard: wizard, code: "AB")

      expect(step).not_to be_valid
      expect(step.errors[:code]).to be_present
    end

    it "rejects a code containing invalid characters" do
      step = described_class.new(wizard: wizard, code: "A-B")

      expect(step).not_to be_valid
      expect(step.errors[:code]).to include("Enter a valid provider code")
    end

    it "rejects a blank code" do
      step = described_class.new(wizard: wizard, code: "")

      expect(step).not_to be_valid
      expect(step.errors[:code]).to include("Enter provider code")
    end
  end

  describe "availability" do
    it "checks whether the normalised code is already taken" do
      expect(ProviderCodeTakenService)
        .to receive(:call)
        .with(code: "ABC", effective_on: effective_on)
        .and_return(false)

      step = described_class.new(wizard: wizard, code: "abc")

      expect(step).to be_valid
    end

    it "rejects a code that is already taken" do
      allow(ProviderCodeTakenService).to receive(:call).and_return(true)

      expect(step).not_to be_valid
      expect(step.errors[:code]).to include("Enter a unique provider code")
    end

    it "does not check availability when the code is invalid" do
      expect(ProviderCodeTakenService).not_to receive(:call)

      step = described_class.new(wizard: wizard, code: "AB")

      expect(step).not_to be_valid
    end
  end
end
