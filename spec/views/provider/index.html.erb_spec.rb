require "rails_helper"

RSpec.describe "providers/index.html.erb", type: :view do
  let(:provider_1) { build_stubbed(:provider, operating_name: "Academy", legal_name: "Academy", urn: "50001") }
  let(:provider_2) { build_stubbed(:provider, operating_name: "Big School", legal_name: "Big old school", urn: "50002") }
  let(:providers) { [provider_1, provider_2] }
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

    render
  end

  it "calls page_data with govuk_number count" do
    expect(view).to have_received(:page_data).with(title: "Providers (2)")
  end

  it "renders the add provider button" do
    expect(rendered_custom_layout).to have_link("Add provider", href: "/providers/new")
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
