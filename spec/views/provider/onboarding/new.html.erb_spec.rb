require "rails_helper"

RSpec.describe "providers/onboarding/new.html.erb", type: :view do
  let(:form) { Providers::IsTheProviderAccredited.new }

  before do
    assign(:form, form)
    allow(view).to receive(:page_data)

    render
  end

  it "calls page_data" do
    expect(view).to have_received(:page_data).with({ error: false,
                                                     header: false,
                                                     title: "Is the provider accredited?",
                                                     subtitle: "Add provider" })
  end

  it "renders the continue button" do
    expect(rendered).to have_button("Continue")
  end

  it "renders heading" do
    caption = "Add provider"
    heading = "Is the provider accredited?"
    expect(rendered).to have_heading("h1", "#{caption}#{heading}")
  end

  it "renders the form" do
    expect(rendered).to have_selector("form")
    expect(rendered).to have_selector("input[name='provider[accreditation_status]']", count: 2)
  end

  it "renders the cancel link" do
    expect(rendered).to have_link("Cancel", href: providers_path)
  end
  it "renders the back link" do
    expect(view.content_for(:breadcrumbs)).to have_back_link(providers_path)
  end

  context "with validation errors" do
    let(:form) do
      provider = Providers::IsTheProviderAccredited.new
      provider.valid?
      provider
    end

    it "calls page_data with error" do
      expect(view).to have_received(:page_data).with({ error: true,
                                                       header: false,
                                                       title: "Is the provider accredited?",
                                                       subtitle: "Add provider" })
    end

    it "renders the error summary" do
      expect(view.content_for(:page_alerts)).to have_error_summary(
        "Select if the provider is accredited"
      )
    end
  end
end
