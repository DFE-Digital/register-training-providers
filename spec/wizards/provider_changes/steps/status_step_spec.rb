RSpec.describe ProviderChanges::Steps::StatusStep do
  subject(:step) { described_class.new(**step_attributes, wizard: wizard, step_id: :new_status) }

  let(:wizard) { instance_double(ProviderChanges::StatusWizard, provider:) }
  let(:provider) { create(:provider) }
  let(:step_attributes) { { new_status: } }
  let(:new_status) { "inactive" }

  describe "validations" do
    it "is valid for a transitionable status" do
      expect(step).to be_valid
    end

    context "when no status is selected" do
      let(:new_status) { nil }

      it "is not valid" do
        step.valid?

        expect(step.errors[:new_status]).to include("Select the new provider status")
      end
    end

    context "when the status is not a transitionable status" do
      let(:new_status) { "archived" }

      it "is not valid" do
        step.valid?

        expect(step.errors[:new_status]).to include("Select a valid provider status")
      end
    end
  end

  describe "#statuses" do
    it "offers the statuses the provider can move to" do
      expect(step.statuses).to eq(
        [
          described_class::Status.new("inactive", "Inactive"),
          described_class::Status.new("offboarded", "Offboarded")
        ]
      )
    end
  end
end
