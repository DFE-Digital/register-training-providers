RSpec.describe ProviderChanges::Steps::UrnStep do
  subject(:step) { described_class.new(wizard:, urn:) }

  let(:wizard) { double(provider:) }
  let(:provider) { create(:provider, urn: "654321") }
  let(:urn) { "123456" }

  describe ".permitted_params" do
    it "permits urn" do
      expect(described_class.permitted_params).to eq(%i[urn])
    end
  end

  describe "validation" do
    it "accepts a six digit URN" do
      expect(step).to be_valid
    end

    it "accepts a five digit URN" do
      step = described_class.new(wizard: wizard, urn: "12345")

      expect(step).to be_valid
    end

    it "rejects a URN that is too short" do
      step = described_class.new(wizard: wizard, urn: "1234")

      expect(step).not_to be_valid
      expect(step.errors[:urn]).to include("Enter a valid unique reference number (URN)")
    end

    it "rejects a URN that is too long" do
      step = described_class.new(wizard: wizard, urn: "1234567")

      expect(step).not_to be_valid
      expect(step.errors[:urn]).to include("Enter a valid unique reference number (URN)")
    end

    it "rejects a URN containing non numeric characters" do
      step = described_class.new(wizard: wizard, urn: "12345A")

      expect(step).not_to be_valid
      expect(step.errors[:urn]).to include("Enter a valid unique reference number (URN)")
    end
  end

  describe "optionality" do
    context "when the provider does not require a URN" do
      let(:provider) { create(:provider, urn: nil) }

      it "allows a blank URN" do
        expect(described_class.new(wizard: wizard, urn: "")).to be_valid
      end
    end

    context "when the provider requires a URN" do
      let(:provider) { create(:provider, :scitt, urn: "654321") }

      it "rejects a blank URN" do
        step = described_class.new(wizard: wizard, urn: "")

        expect(step).not_to be_valid
        expect(step.errors[:urn]).to include("Enter unique reference number (URN)")
      end
    end
  end

  describe "same value prevention" do
    it "accepts a URN different from the provider's current one" do
      expect(step).to be_valid
    end

    it "rejects the provider's current URN" do
      step = described_class.new(wizard: wizard, urn: provider.urn)

      expect(step).not_to be_valid
      expect(step.errors[:urn]).to include("Enter a different unique reference number (URN)")
    end

    it "does not check for the same value when the URN is invalid" do
      step = described_class.new(wizard: wizard, urn: "123")

      expect(step.errors[:urn]).not_to include("Enter a different unique reference number (URN)")
    end
  end
end
