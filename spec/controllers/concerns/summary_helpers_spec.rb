require "rails_helper"

RSpec.describe SummaryHelpers do
  let(:dummy) do
    Class.new { include SummaryHelpers }.new
  end

  describe "#optional_value" do
    context "when the value is present" do
      it "returns a hash with the value as text" do
        expect(dummy.send(:optional_value, "Some Value")).to eq({ text: "Some Value" })
      end
    end

    context "when the value is blank" do
      it "returns the not_entered hash" do
        expect(dummy.send(:optional_value, "")).to eq({ text: "Not entered", classes: "govuk-hint" })
      end

      it "returns the not_entered hash when nil" do
        expect(dummy.send(:optional_value, nil)).to eq({ text: "Not entered", classes: "govuk-hint" })
      end
    end
  end

  describe "#not_entered" do
    it "returns the expected not entered hash" do
      expect(dummy.send(:not_entered)).to eq({ text: "Not entered", classes: "govuk-hint" })
    end
  end
end
