require "rails_helper"

RSpec.describe "providers/type/new.html.erb", type: :view do
  let(:form) { Providers::ProviderType.new(accreditation_status: :accredited) }
  let(:goto) { nil }

  before do
    assign(:form, form)
    allow(view).to receive(:page_data)
    controller.params.merge!(goto:).compact!

    render
  end

  it "calls page_data" do
    expect(view).to have_received(:page_data).with({ error: false,
                                                     header: false,
                                                     title: "Provider type",
                                                     subtitle: "Add provider" })
  end

  it "renders the continue button" do
    expect(rendered).to have_button("Continue")
  end

  it "renders heading" do
    caption = "Add provider"
    heading = "Provider type"
    expect(rendered).to have_heading("h1", "#{caption}#{heading}")
  end

  it "renders the form" do
    expect(rendered).to have_selector("form")
    expect(rendered).to have_selector("input[name='provider[provider_type]']", count: 3)
  end

  it "renders option for scitt" do
    expect(rendered).to have_selector("input[value=\"scitt\"]", count: 1)
  end

  context "with provider as unaccredited" do
    let(:form) { Providers::ProviderType.new(accreditation_status: :unaccredited) }

    it "renders the form" do
      expect(rendered).to have_selector("form")
      expect(rendered).to have_selector("input[name='provider[provider_type]']", count: 3)
    end

    it "renders option for school" do
      expect(rendered).to have_selector("input[value=\"school\"]", count: 1)
    end
  end

  it "renders the cancel link" do
    expect(rendered).to have_link("Cancel", href: providers_path)
  end
  it "renders the back link" do
    expect(view.content_for(:breadcrumbs)).to have_back_link(new_provider_onboarding_path)
  end

  context "when goto is confirm" do
    let(:goto) { "confirm" }

    it "renders the back link" do
      expect(view.content_for(:breadcrumbs)).to have_back_link(new_provider_confirm_path)
    end
  end

  context "with validation errors" do
    let(:form) do
      provider = Providers::ProviderType.new(accreditation_status: :accredited)
      provider.valid?
      provider
    end

    it "calls page_data with error" do
      expect(view).to have_received(:page_data).with({ error: true,
                                                       header: false,
                                                       title: "Provider type",
                                                       subtitle: "Add provider" })
    end

    it "renders the error summary" do
      expect(view.content_for(:page_alerts)).to have_error_summary(
        "Select provider type"
      )
    end
  end
end
