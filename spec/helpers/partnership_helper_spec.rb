RSpec.describe PartnershipHelper, type: :helper do
  describe "#partnership_rows" do
    let(:partnership) { build_stubbed(:partnership, duration: (Time.zone.local(Time.zone.now.year, 7, 1)...Time.zone.local(Time.zone.now.year + 1, 8, 31))) }

    it "returns the expected rows" do
      expect(helper.partnership_rows(partnership)).to eq([
        {
          key: { text: "Accredited Provider" },
          value: { text: partnership.accredited_provider.operating_name },
        },
        {
          key: { text: "Training partner" },
          value: { text: partnership.provider.operating_name },
        },
        {
          key: { text: "Partnership dates" },
          value: { text: "<dl class=\"govuk-summary-list\"><div class=\"govuk-summary-list__row\"><dt class=\"govuk-summary-list__key\">Starts on</dt><dd class=\"govuk-summary-list__value\">#{partnership.duration.begin&.to_fs(:govuk)}</dd></div><div class=\"govuk-summary-list__row\"><dt class=\"govuk-summary-list__key\">Ends on</dt><dd class=\"govuk-summary-list__value\">{text: &quot;#{partnership.duration.end&.to_fs(:govuk)}&quot;}</dd></div></dl>" },
        },
        {
          key: { text: "Academic years" },
          value: { text: "<dl class=\"govuk-summary-list\"><ul class=\"govuk-list govuk-list--bullet\"></ul></dl>" }
        }
      ])
    end
  end
end
