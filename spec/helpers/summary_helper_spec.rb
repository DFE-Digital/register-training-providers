require "rails_helper"

RSpec.describe SummaryHelper, type: :helper do
  describe "#optional_value" do
    context "when the value is present" do
      it "returns a hash with the value as text" do
        expect(helper.optional_value("Some Value")).to eq({ text: "Some Value" })
      end
    end

    context "when the value is blank" do
      it "returns the not_entered hash" do
        expect(helper.optional_value("")).to eq({ text: "Not entered", classes: "govuk-hint" })
      end

      it "returns the not_entered hash when nil" do
        expect(helper.optional_value(nil)).to eq({ text: "Not entered", classes: "govuk-hint" })
      end
    end
  end

  describe "#not_entered" do
    it "returns the expected not entered hash" do
      expect(helper.not_entered).to eq({ text: "Not entered", classes: "govuk-hint" })
    end
  end

  describe "#provider_summary_cards" do
    let(:provider) { build_stubbed(:provider, legal_name: nil, urn: "50000") }
    let(:providers) { [provider] }
    require "nokogiri"

    it "returns the expected not entered hash" do
      result = helper.provider_summary_cards(providers).first
      title_html = result[:title]

      doc = Nokogiri::HTML.fragment(title_html)
      link = doc.at_css("a")

      expect(link["href"]).to eq("/providers/#{provider.id}")
      expect(link.text).to eq(provider.operating_name)

      expect(result[:rows]).to match_array([
        { key: { text: "Provider type" }, value: { text: provider.provider_type_label } },
        { key: { text: "Accreditation type" }, value: { text: provider.accreditation_status_label } },
        { key: { text: "Operating name" }, value: { text: provider.operating_name } },
        { key: { text: "Legal name" }, value: { text: "Not entered", classes: "govuk-hint" } },
        { key: { text: "UK provider reference number (UKPRN)" }, value: { text: provider.ukprn } },
        { key: { text: "Unique reference number (URN)" }, value: { text: provider.urn } },
        { key: { text: "Provider code" }, value: { text: provider.code } },
      ])
    end
  end

  describe "#user_rows" do
    let(:user) { build_stubbed(:user) }
    let(:change_path) { "/users/#{user.id}/edit" }

    it "returns the expected rows" do
      expect(helper.user_rows(user, change_path)).to eq([
        {
          key: { text: "First name" },
          value: { text: user.first_name },
          actions: [{ href: change_path, visually_hidden_text: "first name" }]
        },
        {
          key: { text: "Last name" },
          value: { text: user.last_name },
          actions: [{ href: change_path, visually_hidden_text: "last name" }]
        },
        {
          key: { text: "Email address" },
          value: { text: user.email },
          actions: [{ href: change_path, visually_hidden_text: "email address" }]
        }
      ])
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
    let(:provider) { build_stubbed(:provider, legal_name: nil, urn: nil) }

    it "returns the expected rows with 'Not entered' where applicable" do
      expect(helper.provider_details_rows(provider)).to eq([
        {
          key: { text: "Provider type" },
          value: { text: provider.provider_type_label },
        },
        {
          key: { text: "Accreditation type" },
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
      ])
    end

    context "when all values are present" do
      let(:provider) { build_stubbed(:provider, :scitt) }

      it "returns the expected rows without 'Not entered'" do
        expect(helper.provider_details_rows(provider)).to eq([
          {
            key: { text: "Provider type" },
            value: { text: provider.provider_type_label },
          },
          {
            key: { text: "Accreditation type" },
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
