require "rails_helper"

RSpec.describe ProviderHelper, type: :helper do
  let(:current_academic_year) { AcademicYearCalculator.current_academic_year }
  let(:onboarded_at) { 1.year.ago }

  describe "#provider_summary_cards" do
    let(:provider) { create(:provider, legal_name: nil, operating_name: "School of learning", urn: "50000", onboarded_at: onboarded_at, first_active_at: onboarded_at) }
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
        { key: { text: "Active academic years" }, value: { text: "<ul class=\"govuk-list govuk-list--bullet\"><li>#{current_academic_year} to #{current_academic_year + 1} - current</li></ul>" } },
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
      let(:provider) { build_stubbed(:provider, :archived, onboarded_at: onboarded_at, first_active_at: onboarded_at) }

      it "renders the archived tag in the title" do
        result = helper.provider_summary_cards([provider]).first
        doc = Nokogiri::HTML.fragment(result[:title])

        expect(doc.text).to include("Archived")
      end
    end

    context "when debug mode is enabled" do
      let(:provider) { build_stubbed(:provider, onboarded_at: onboarded_at, first_active_at: onboarded_at) }
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
      let(:change_provider_type_path) { "/providers/new/type" }
      let(:change_provider_onboarding_path) { "/providers/new" }
      let(:change_provider_first_become_active_path) { "/providers/new/first-become-active" }

      it "returns the expected rows without 'Not entered'" do
        expect(helper.provider_rows(provider, change_path, change_provider_type_path:, change_provider_onboarding_path:, change_provider_first_become_active_path:)).to eq([
          {
            key: { text: "Onboard at" },
            value: { text: Time.zone.today.to_fs(:govuk) },
            actions: [{ href: change_provider_onboarding_path, visually_hidden_text: "onboarded date" }]
          },
          {
            key: { text: "First active at" },
            value: { text: Time.zone.today.to_fs(:govuk) },
            actions: [{ href: change_provider_first_become_active_path, visually_hidden_text: "first active date" }]
          },
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
    let(:provider) { create(:provider, operating_name: "Test", legal_name: nil, urn: nil, onboarded_at: onboarded_at, first_active_at: onboarded_at) }

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
        { key: { text: "Onboard at" }, value: { text: provider.onboarded_at.to_fs(:govuk) } },
        { key: { text: "First active at" }, value: { text: provider.first_active_at.to_fs(:govuk) } },
        {
          key: { text: "Active academic years" },
          value: { text: "<ul class=\"govuk-list govuk-list--bullet\"><li>#{current_academic_year} to #{current_academic_year + 1} - current</li></ul>" },
        },
        {
          key: { text: "Inactive periods" },
          value: { text: "<p>No inactive periods</p>" }
        },
      ])
    end

    context "when all values are present" do
      let(:provider) { create(:provider, :scitt, onboarded_at: onboarded_at, first_active_at: onboarded_at) }

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
          { key: { text: "Onboard at" }, value: { text: provider.onboarded_at.to_fs(:govuk) } },
          { key: { text: "First active at" }, value: { text: provider.first_active_at.to_fs(:govuk) } },
          {
            key: { text: "Active academic years" },
            value: { text: "<ul class=\"govuk-list govuk-list--bullet\"><li>#{current_academic_year} to #{current_academic_year + 1} - current</li></ul>" },
          },
          {
            key: { text: "Inactive periods" },
            value: { text: "<p>No inactive periods</p>" }
          },
        ])
      end
    end

    context "when the provider has inactive periods" do
      let(:onboard_date) { build_academic_year_date(start_academic_year) }
      let(:start_academic_year) { current_academic_year - 3 }
      let(:start_inactive_period) { start_academic_year + 1 }
      let(:end_inactive_period) { previous_academic_year }
      let(:active_academic_years_list) do
        ((start_academic_year..current_academic_year).to_a - (start_inactive_period..end_inactive_period).to_a)
            .sort
            .reverse
            .map { |year|
              text = "#{year} to #{year + 1}"
              text += " - current" if year == current_academic_year
              "<li>#{text}</li>"
            }
            .join
      end
      let(:inactive_period) do
        { start_date: build_academic_year_date(start_inactive_period),
          end_date: build_academic_year_date(previous_academic_year),
          reason_for_inactive: "None given" }
      end
      let(:provider) do
        create(:provider, :scitt, inactive_periods: [inactive_period], onboarded_at: onboard_date, first_active_at: onboard_date)
      end
      let!(:academic_years) do
        (start_academic_year..current_academic_year).to_a.each do |year|
          create(:academic_year, academic_year: year)
        end
      end

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
            key: { text: "Onboard at" },
            value: { text: provider.onboarded_at.to_fs(:govuk) }
          },
          {
            key: { text: "First active at" },
            value: { text: provider.first_active_at.to_fs(:govuk) }
          },
          {
            key: { text: "Active academic years" },
            value: { text: "<ul class=\"govuk-list govuk-list--bullet\">#{active_academic_years_list}</ul>" },
          },
          {
            key: { text: "Inactive periods" },
            value: { text: "<ul class=\"govuk-list govuk-list\"><li><dl class=\"govuk-summary-list\"><div class=\"govuk-summary-list__row\"><dt class=\"govuk-summary-list__key\">Starts on</dt><dd class=\"govuk-summary-list__value\">#{inactive_period[:start_date].to_date.to_fs(:govuk)}</dd></div><div class=\"govuk-summary-list__row\"><dt class=\"govuk-summary-list__key\">Ends on</dt><dd class=\"govuk-summary-list__value\">#{inactive_period[:end_date].to_date.to_fs(:govuk)}</dd></div></dl></li></ul>" }
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
