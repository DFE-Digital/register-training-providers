RSpec.describe ProviderChanges::Steps::ProviderTypeStep do
  subject(:step) { described_class.new(wizard:, provider_type:) }

  let(:wizard) { double(provider:) }
  let(:provider) { create(:provider) }
  let(:provider_type) { "scitt" }

  describe ".permitted_params" do
    it "permits provider_type only" do
      expect(described_class.permitted_params).to eq(%i[provider_type])
    end
  end

  describe "validation" do
    it "accepts a valid provider type" do
      expect(step).to be_valid
    end

    it "requires a provider type" do
      step = described_class.new(wizard: wizard, provider_type: nil)

      expect(step).not_to be_valid
      expect(step.errors[:provider_type]).to include("Select provider type")
    end

    it "reports only the presence error for a blank provider type" do
      step = described_class.new(wizard: wizard, provider_type: "")

      expect(step).not_to be_valid
      expect(step.errors[:provider_type]).to eq(["Select provider type"])
    end

    it "reports only the inclusion error when an invalid value matches the current type" do
      wizard = double(provider: double(provider_type: "retired_type"))
      step = described_class.new(wizard: wizard, provider_type: "retired_type")

      expect(step).not_to be_valid
      expect(step.errors[:provider_type]).to include("Select a valid provider type")
      expect(step.errors[:provider_type]).not_to include("Select a different provider type")
    end

    it "accepts Other" do
      step = described_class.new(wizard: wizard, provider_type: "other")

      expect(step).to be_valid
    end

    it "rejects an unknown provider type" do
      step = described_class.new(wizard: wizard, provider_type: "invalid_type")

      expect(step).not_to be_valid
      expect(step.errors[:provider_type]).to include("Select a valid provider type")
    end
  end

  describe "same value prevention" do
    it "accepts a provider type different from the provider's current one" do
      expect(step).to be_valid
    end

    it "rejects the provider's current provider type" do
      step = described_class.new(wizard: wizard, provider_type: provider.provider_type)

      expect(step).not_to be_valid
      expect(step.errors[:provider_type]).to include("Select a different provider type")
    end
  end
end
