require "rails_helper"

RSpec.describe "providers/index.html.erb", type: :view do
  let(:provider_1) { build_stubbed(:provider, operating_name: "Academy", legal_name: "Academy", urn: "50001") }
  let(:provider_2) { build_stubbed(:provider, operating_name: "Big School", legal_name: "Big old school", urn: "50002") }
  let(:providers) { [provider_1, provider_2] }
  let(:count) { providers.size }
  let(:pagy) { Pagy.new(count: count, page: 1) }

  let(:pagination_component) { instance_double(PaginationDisplay::View) }

  before do
    assign(:records, providers)
    assign(:pagy, pagy)
    allow(view).to receive(:page_data)

    render
  end

  it "calls page_data with govuk_number count" do
    expect(view).to have_received(:page_data).with(title: "Providers (2)")
  end

  it "renders the add provider button" do
    expect(rendered).to have_link("Add provider", href: "/providers/new")
  end

  it "renders each provider in the summary card" do
    providers.each do |provider|
      expect(rendered).to have_selector("h2", text: provider.operating_name)

      expect(rendered).to have_selector(".govuk-summary-list__key", text: "Provider type")
      expect(rendered).to have_selector(".govuk-summary-list__value", text: provider.provider_type_label)
      expect(rendered).to have_selector(".govuk-summary-list__key", text: "Operating name")
      expect(rendered).to have_selector(".govuk-summary-list__value", text: provider.operating_name)
      expect(rendered).to have_selector(".govuk-summary-list__key", text: "Legal name")
      expect(rendered).to have_selector(".govuk-summary-list__value", text: provider.legal_name)
      expect(rendered).to have_selector(".govuk-summary-list__key", text: "UK provider reference number (UKPRN)")
      expect(rendered).to have_selector(".govuk-summary-list__value", text: provider.ukprn)
      expect(rendered).to have_selector(".govuk-summary-list__key", text: "Unique reference number (URN)")
      expect(rendered).to have_selector(".govuk-summary-list__value", text: provider.urn)
      expect(rendered).to have_selector(".govuk-summary-list__key", text: "Provider code")
      expect(rendered).to have_selector(".govuk-summary-list__value", text: provider.code)
    end
  end

  it "does not renders the pagination component" do
    expect(rendered).not_to have_pagination
  end

  context "when pagy count is over 25" do
    let(:count) { 1_000_000 }
    it "calls page_data with govuk_number count" do
      expect(view).to have_received(:page_data).with(title: "Providers (1,000,000)")
    end
    it "does renders the pagination component" do
      expect(rendered).to have_pagination
    end
  end
end
