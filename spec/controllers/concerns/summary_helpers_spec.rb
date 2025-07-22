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

  describe "#summary_cards" do
    let(:provider) { build(:provider, legal_name: nil, urn: "50000") }
    let(:providers) { [provider] }
    it "returns the expected not entered hash" do
      expect(dummy.send(:provider_summary_cards, providers)).to match_array([{
        title: provider.operating_name,
        rows: [

          { key: { text: "Provider type" },
            value: { text: provider.provider_type_label }, },
          { key: { text: "Operating name" },
            value: { text: provider.operating_name }, },
          { key: { text: "Legal name" },
            value: { text: "Not entered", classes: "govuk-hint" } },
          { key: { text: "UK provider reference number (UKPRN)" },
            value: { text: provider.ukprn }, },
          { key: { text: "Unique reference number (URN)" },
            value: { text: provider.urn }, },
          { key: { text: "Provider code" },
            value: { text: provider.code }, },
        ]
      }])
    end
  end
end
