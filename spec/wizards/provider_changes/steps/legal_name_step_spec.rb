RSpec.describe ProviderChanges::Steps::LegalNameStep do
  subject(:step) { described_class.new(wizard:, legal_name:) }

  let(:wizard) { double(provider:) }
  let(:provider) { create(:provider, legal_name: "Old provider name") }
  let(:legal_name) { "New provider name" }

  describe ".permitted_params" do
    it "permits legal_name" do
      expect(described_class.permitted_params).to eq(%i[legal_name])
    end
  end

  describe "validation" do
    it "accepts a legal name" do
      expect(step).to be_valid
    end

    it "accepts a blank legal name" do
      step = described_class.new(wizard: wizard, legal_name: "")

      expect(step).to be_valid
    end

    it "strips surrounding whitespace from the legal name" do
      step = described_class.new(wizard: wizard, legal_name: "  New provider name  ")

      expect(step).to be_valid
      expect(step.legal_name).to eq("New provider name")
    end

    it "treats a whitespace-only legal name as blank" do
      step = described_class.new(wizard: wizard, legal_name: "   ")

      expect(step).to be_valid
      expect(step.legal_name).to eq("")
    end
  end

  describe "same value prevention" do
    it "accepts a legal name different from the provider's current one" do
      expect(step).to be_valid
    end

    it "rejects the provider's current legal name" do
      step = described_class.new(wizard: wizard, legal_name: provider.legal_name)

      expect(step).not_to be_valid
      expect(step.errors[:legal_name]).to include("Enter a different legal name")
    end

    it "rejects the current legal name after stripping surrounding whitespace" do
      step = described_class.new(wizard: wizard, legal_name: "  #{provider.legal_name}  ")

      expect(step).not_to be_valid
      expect(step.errors[:legal_name]).to include("Enter a different legal name")
    end

    it "does not check for the same value when the legal name is blank" do
      step = described_class.new(wizard: wizard, legal_name: "")

      expect(step.errors[:legal_name]).not_to include("Enter a different legal name")
    end
  end
end
