RSpec.describe ProviderChanges::Steps::ReasonsStep do
  subject(:step) { described_class.new(**step_attributes, wizard: nil, step_id: :reasons) }

  let(:step_attributes) do
    {
      reasons:,
      other_reason:
    }
  end

  let(:reasons) { ["no_current_cohorts"] }
  let(:other_reason) { nil }

  describe "validations" do
    it "is valid with at least one reason" do
      expect(step).to be_valid
    end

    context "when no reason is selected" do
      let(:reasons) { [] }

      it "is not valid" do
        step.valid?

        expect(step.errors[:reasons]).to include("Select at least one reason")
      end
    end

    context "when the reason is not one of the offered reasons" do
      let(:reasons) { %w[bogus] }

      it "is not valid" do
        step.valid?

        expect(step.errors[:reasons]).to include("Select a valid reason")
      end
    end

    context "when the other reason is selected but left blank" do
      let(:reasons) { ["other"] }

      it "is not valid" do
        step.valid?

        expect(step.errors[:other_reason]).to include("Enter a reason")
      end
    end

    context "when the other reason exceeds 255 characters" do
      let(:reasons) { ["other"] }
      let(:other_reason) { "b" * 256 }

      it "is not valid" do
        step.valid?

        expect(step.errors[:other_reason]).to include("The reason must be 255 characters or fewer")
      end
    end

    context "when the other reason is exactly 255 characters" do
      let(:reasons) { ["other"] }
      let(:other_reason) { "b" * 255 }

      it "is valid" do
        expect(step).to be_valid
      end
    end
  end

  describe "#other_reason_selected?" do
    context "when other is among the selected reasons" do
      let(:reasons) { ["other"] }
      let(:other_reason) { "Something else" }

      it "returns true" do
        expect(step.other_reason_selected?).to be(true)
      end
    end

    context "when other is not selected but stale text remains" do
      let(:reasons) { ["no_current_cohorts"] }
      let(:other_reason) { "Stale reason from a previous selection" }

      it "returns false, so the checkbox is not re-ticked" do
        expect(step.other_reason_selected?).to be(false)
      end
    end
  end

  describe "#reasons_for_inactive" do
    it "returns the reason list the checkboxes offer" do
      expect(step.reasons_for_inactive.map(&:name)).to eq(
        [
          "No current cohorts",
          "Operations temporarily paused",
          "Staffing or capacity issues",
          "Financial viability"
        ]
      )
    end
  end
end
