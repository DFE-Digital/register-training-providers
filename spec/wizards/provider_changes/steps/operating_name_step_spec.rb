RSpec.describe ProviderChanges::Steps::OperatingNameStep do
  subject(:step) { described_class.new(wizard:, operating_name:) }

  let(:wizard) { double(provider:) }
  let(:provider) { create(:provider, operating_name: "Old provider name") }
  let(:operating_name) { "New provider name" }

  describe ".permitted_params" do
    it "permits operating_name" do
      expect(described_class.permitted_params).to eq(%i[operating_name])
    end
  end

  describe "validation" do
    it "accepts an operating name" do
      expect(step).to be_valid
    end
  end

  describe "presence" do
    it "rejects a blank operating name" do
      step = described_class.new(wizard: wizard, operating_name: "")

      expect(step).not_to be_valid
      expect(step.errors[:operating_name]).to include("Enter operating name")
    end
  end

  describe "same value prevention" do
    it "accepts an operating name different from the provider's current one" do
      expect(step).to be_valid
    end

    it "rejects the provider's current operating name" do
      step = described_class.new(wizard: wizard, operating_name: provider.operating_name)

      expect(step).not_to be_valid
      expect(step.errors[:operating_name]).to include("Enter a different operating name")
    end

    it "does not check for the same value when the operating name is blank" do
      step = described_class.new(wizard: wizard, operating_name: "")

      expect(step.errors[:operating_name]).not_to include("Enter a different operating name")
    end
  end
end
