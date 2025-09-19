require "rails_helper"

RSpec.describe "providers/index.html.erb", type: :view do
  let(:provider_1) { build_stubbed(:provider, operating_name: "Academy", legal_name: "Academy", urn: "50001") }
  let(:provider_2) { build_stubbed(:provider, operating_name: "Big School", legal_name: "Big old school", urn: "50002") }
  let(:provider_3) { build_stubbed(:provider, :archived, operating_name: "College", legal_name: "New College", urn: "50003") }
  let(:providers) { [provider_1, provider_2, provider_3] }
  let(:count) { providers.size }
  let(:pagy) { Pagy.new(count: count, page: 1) }

  let(:pagination_component) { instance_double(PaginationDisplay::View) }

  let(:rendered_custom_layout) { view.content_for(:custom_layout) }

  before do
    assign(:records, providers)
    assign(:pagy, pagy)
    allow(view).to receive(:page_data)
    def view.provider_filters
      {}
    end

    def view.keywords
      {}
    end

    render
  end

  it "calls page_data with govuk_number count" do
    expect(view).to have_received(:page_data).with(title: "Providers (3)")
  end

  it "renders the add provider button" do
    expect(rendered_custom_layout).to have_link("Add provider", href: "/providers/new")
  end

  it "renders the correct title for provider summary cards" do
    expect(rendered_custom_layout).to have_css(".govuk-summary-card__title", text: provider_1.operating_name)
    expect(rendered_custom_layout).to have_css(".govuk-summary-card__title", text: provider_2.operating_name)
    expect(rendered_custom_layout).to have_css(".govuk-summary-card__title", text: "#{provider_3.operating_name} Archived")
  end

  it "does not renders the pagination component" do
    expect(rendered_custom_layout).not_to have_pagination
  end

  context "when pagy count causes paginations" do
    let(:count) { 1_000_000 }
    it "calls page_data with govuk_number count" do
      expect(view).to have_received(:page_data).with(title: "Providers (1,000,000)")
    end
    it "does renders the pagination component" do
      expect(rendered_custom_layout).to have_pagination
    end
  end
end
