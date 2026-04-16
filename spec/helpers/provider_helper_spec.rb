require "rails_helper"

RSpec.describe ProviderHelper, type: :helper do
  describe "#provider_summary_cards" do
    let(:provider) { create(:provider, legal_name: nil, operating_name: "School of learning", urn: "50000") }
    let(:providers) { [provider] }

    it "returns the expected not entered hash" do
      result = helper.provider_summary_cards(providers).first
      title_html = result[:title]

      doc = Nokogiri::HTML.fragment(title_html)
      link = doc.at_css("a")
      expect(link["href"]).to eq("/providers/#{provider.id}")
      expect(link.text).to eq(provider.operating_name)

      meta = doc.at_css("p.govuk-hint")
      expect(meta).not_to be_nil
      expect(meta.inner_html).to include("Provider code:")
      expect(meta.inner_html).to include("UKPRN")
      expect(meta.inner_html).to include("URN")
      expect(meta.text).to include(provider.urn)

      expect(result[:rows]).to match_array([
        { key: { text: "Provider type" }, value: { text: provider.provider_type_label } },
        { key: { text: "Accreditation status" }, value: { text: provider.accreditation_status_label } },
        { key: { text: "Operating name" }, value: { text: provider.operating_name } },
        { key: { text: "Legal name" }, value: { text: "Not entered", classes: "govuk-hint" } },
        { key: { text: "Academic years" }, value: { text: '<ul class="govuk-list govuk-list--bullet"><li>2025 to 2026 - current</li></ul>' } },
      ])
    end

    context "when provider has no identifiers" do
      let(:provider) do
        build_stubbed(:provider, code: nil, ukprn: nil, urn: nil)
      end

      it "does not render the provider meta block" do
        result = helper.provider_summary_cards([provider]).first
        doc = Nokogiri::HTML.fragment(result[:title])

        expect(doc.at_css("p.govuk-hint")).to be_nil
      end
    end

    context "when provider is archived" do
      let(:provider) { build_stubbed(:provider, :archived) }

      it "renders the archived tag in the title" do
        result = helper.provider_summary_cards([provider]).first
        doc = Nokogiri::HTML.fragment(result[:title])

        expect(doc.text).to include("Archived")
      end
    end

    context "when debug mode is enabled" do
      let(:provider) { build_stubbed(:provider) }
      let(:providers) { [provider] }

      before do
        allow(helper).to receive(:params).and_return({ debug: "true" })
      end

      it "includes debug=true in the provider link" do
        result = helper.provider_summary_cards(providers).first
        title_html = result[:title]

        doc = Nokogiri::HTML.fragment(title_html)
        link = doc.at_css("a")

        expect(link["href"]).to eq("/providers/#{provider.id}?debug=true")
      end
    end

    context "when debug mode is not enabled" do
      let(:provider) { build_stubbed(:provider) }
      let(:providers) { [provider] }

      before do
        allow(helper).to receive(:params).and_return({})
      end

      it "does not include debug param in the provider link" do
        result = helper.provider_summary_cards(providers).first
        title_html = result[:title]

        doc = Nokogiri::HTML.fragment(title_html)
        link = doc.at_css("a")

        expect(link["href"]).to eq("/providers/#{provider.id}")
      end
    end
  end

  describe "#provider_rows" do
    let(:provider) { build_stubbed(:provider, legal_name: nil, urn: nil) }

    let(:change_provider_type_path) { nil }
    let(:change_path) { "/providers/details/edit" }

    it "returns the expected rows and with 'Not entered' where applicable" do
      expect(helper.provider_rows(provider, change_path, change_provider_type_path:)).to eq([
        {
          key: { text: "Operating name" },
          value: { text: provider.operating_name },
          actions: [{ href: change_path, visually_hidden_text: "operating name" }]
        },
        {
          key: { text: "Legal name" },
          value: { text: "Not entered", classes: "govuk-hint" },
          actions: [{ href: change_path, visually_hidden_text: "legal name" }]
        },
        {
          key: { text: "UK provider reference number (UKPRN)" },
          value: { text: provider.ukprn },
          actions: [{ href: change_path, visually_hidden_text: "UK provider reference number (UKPRN)" }]
        },
        {
          key: { text: "Unique reference number (URN)" },
          value: { text: "Not entered", classes: "govuk-hint" },
          actions: [{ href: change_path, visually_hidden_text: "unique reference number (URN)" }]
        },
        {
          key: { text: "Provider code" },
          value: { text: provider.code },
          actions: [{ href: change_path, visually_hidden_text: "provider code" }]
        }
      ])
    end

    context "when all values are present" do
      let(:provider) { build_stubbed(:provider, :scitt) }
      let(:change_provider_type_path) { "/providers/type/edit" }

      it "returns the expected rows without 'Not entered'" do
        expect(helper.provider_rows(provider, change_path, change_provider_type_path:)).to eq([
          {
            key: { text: "Provider type" },
            value: { text: provider.provider_type_label },
            actions: [{ href: change_provider_type_path, visually_hidden_text: "provider type" }]
          },
          {
            key: { text: "Operating name" },
            value: { text: provider.operating_name },
            actions: [{ href: change_path, visually_hidden_text: "operating name" }]
          },
          {
            key: { text: "Legal name" },
            value: { text: provider.legal_name },
            actions: [{ href: change_path, visually_hidden_text: "legal name" }]
          },
          {
            key: { text: "UK provider reference number (UKPRN)" },
            value: { text: provider.ukprn },
            actions: [{ href: change_path, visually_hidden_text: "UK provider reference number (UKPRN)" }]
          },
          {
            key: { text: "Unique reference number (URN)" },
            value: { text: provider.urn },
            actions: [{ href: change_path, visually_hidden_text: "unique reference number (URN)" }]
          },
          {
            key: { text: "Provider code" },
            value: { text: provider.code },
            actions: [{ href: change_path, visually_hidden_text: "provider code" }]
          }
        ])
      end
    end
  end

  describe "#provider_details_rows" do
    let(:provider) { create(:provider, operating_name: "Test", legal_name: nil, urn: nil) }

    it "returns the expected rows with 'Not entered' where applicable" do
      expect(helper.provider_details_rows(provider)).to eq([
        {
          key: { text: "Provider type" },
          value: { text: provider.provider_type_label },
        },
        {
          key: { text: "Accreditation status" },
          value: { text: provider.accreditation_status_label },
        },
        {
          key: { text: "Operating name" },
          value: { text: provider.operating_name },
          actions: [{ href: edit_provider_path(provider), visually_hidden_text: "operating name" }],
        },
        {
          key: { text: "Legal name" },
          value: { text: "Not entered", classes: "govuk-hint" },
          actions: [{ href: edit_provider_path(provider), visually_hidden_text: "legal name" }],
        },
        {
          key: { text: "UK provider reference number (UKPRN)" },
          value: { text: provider.ukprn },
          actions: [{ href: edit_provider_path(provider), visually_hidden_text: "UK provider reference number (UKPRN)" }],
        },
        {
          key: { text: "Unique reference number (URN)" },
          value: { text: "Not entered", classes: "govuk-hint" },
          actions: [{ href: edit_provider_path(provider), visually_hidden_text: "unique reference number (URN)" }],
        },
        {
          key: { text: "Provider code" },
          value: { text: provider.code },
          actions: [{ href: edit_provider_path(provider), visually_hidden_text: "provider code" }],
        },
        {
          key: { text: "Academic years" },
          value: { text: '<ul class="govuk-list govuk-list--bullet"><li>2025 to 2026 - current</li></ul>' },
          actions: [{ href: edit_provider_path(provider), visually_hidden_text: "academic years" }],
        },
      ])
    end

    context "when all values are present" do
      let(:provider) { create(:provider, :scitt) }

      it "returns the expected rows without 'Not entered'" do
        expect(helper.provider_details_rows(provider)).to eq([
          {
            key: { text: "Provider type" },
            value: { text: provider.provider_type_label },
          },
          {
            key: { text: "Accreditation status" },
            value: { text: provider.accreditation_status_label },
          },
          {
            key: { text: "Operating name" },
            value: { text: provider.operating_name },
            actions: [{ href: edit_provider_path(provider), visually_hidden_text: "operating name" }],
          },
          {
            key: { text: "Legal name" },
            value: { text: provider.legal_name },
            actions: [{ href: edit_provider_path(provider), visually_hidden_text: "legal name" }],
          },
          {
            key: { text: "UK provider reference number (UKPRN)" },
            value: { text: provider.ukprn },
            actions: [{ href: edit_provider_path(provider), visually_hidden_text: "UK provider reference number (UKPRN)" }],
          },
          {
            key: { text: "Unique reference number (URN)" },
            value: { text: provider.urn },
            actions: [{ href: edit_provider_path(provider), visually_hidden_text: "unique reference number (URN)" }],
          },
          {
            key: { text: "Provider code" },
            value: { text: provider.code },
            actions: [{ href: edit_provider_path(provider), visually_hidden_text: "provider code" }],
          },
          {
            key: { text: "Academic years" },
            value: { text: '<ul class="govuk-list govuk-list--bullet"><li>2025 to 2026 - current</li></ul>' },
            actions: [{ href: edit_provider_path(provider), visually_hidden_text: "academic years" }],
          },
        ])
      end
    end

    context "when the provider is archived" do
      let(:provider) { build_stubbed(:provider, :archived) }

      it "returns the expected rows without actions" do
        rows = helper.provider_details_rows(provider)
        expect(rows).to all(satisfy { |row| !row.key?(:actions) })
      end
    end
  end
end
