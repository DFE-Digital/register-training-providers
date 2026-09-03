RSpec.describe ProviderChanges::Steps::EffectiveAcademicYearStep do
  subject(:step) { described_class.new(wizard:) }

  let(:wizard) { double }

  describe ".permitted_params" do
    it "permits effective_on" do
      expect(described_class.permitted_params).to eq(%i[effective_on])
    end
  end

  describe "validations" do
    it "requires an effective date" do
      step = described_class.new(wizard: wizard, effective_on: nil)

      expect(step).not_to be_valid
      expect(step.errors[:effective_on]).to include("Select an academic year")
    end
  end
end
