RSpec.describe ProviderChanges::Steps::UkprnStep do
  subject(:step) { described_class.new(wizard:, ukprn:) }

  let(:wizard) { double(provider:) }
  let(:provider) { create(:provider, ukprn: "87654321") }
  let(:ukprn) { "12345678" }

  describe ".permitted_params" do
    it "permits ukprn" do
      expect(described_class.permitted_params).to eq(%i[ukprn])
    end
  end

  describe "validation" do
    it "accepts a valid eight-digit UKPRN" do
      expect(step).to be_valid
    end

    it "rejects a blank UKPRN" do
      step = described_class.new(wizard: wizard, ukprn: "")

      expect(step).not_to be_valid
      expect(step.errors[:ukprn]).to include("Enter UK provider reference number")
    end

    it "rejects a UKPRN that is not eight digits" do
      step = described_class.new(wizard: wizard, ukprn: "123")

      expect(step).not_to be_valid
      expect(step.errors[:ukprn]).to include("Enter a valid UK provider reference number")
    end

    it "rejects a UKPRN containing non numeric characters" do
      step = described_class.new(wizard: wizard, ukprn: "1234567A")

      expect(step).not_to be_valid
      expect(step.errors[:ukprn]).to include("Enter a valid UK provider reference number")
    end

    it "rejects a UKPRN that is longer than eight digits" do
      step = described_class.new(wizard: wizard, ukprn: "123456789")

      expect(step).not_to be_valid
      expect(step.errors[:ukprn]).to include("Enter a valid UK provider reference number")
    end
  end

  describe "same value prevention" do
    it "accepts a UKPRN different from the provider's current one" do
      expect(step).to be_valid
    end

    it "rejects the provider's current UKPRN" do
      step = described_class.new(wizard: wizard, ukprn: provider.ukprn)

      expect(step).not_to be_valid
      expect(step.errors[:ukprn]).to include("Enter a different UK provider reference number")
    end

    it "does not check for the same value when the UKPRN is invalid" do
      step = described_class.new(wizard: wizard, ukprn: "123")

      expect(step).not_to be_valid
      expect(step.errors[:ukprn]).not_to include("Enter a different UK provider reference number")
    end
  end
end
