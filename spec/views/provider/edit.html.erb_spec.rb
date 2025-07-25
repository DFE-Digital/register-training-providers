require "rails_helper"

RSpec.describe "providers/edit.html.erb", type: :view do
  let(:provider) { create(:provider) }
  let(:goto) { nil }

  before do
    assign(:provider, provider)
    allow(view).to receive(:page_data)
    controller.params.merge!(goto:).compact!

    render
  end

  it "calls page_data" do
    expect(view).to have_received(:page_data).with({ error: false,
                                                     header: false,
                                                     subtitle: "Provider details",
                                                     title: provider.operating_name })
  end

  it "renders the continue button" do
    expect(rendered).to have_button("Continue")
  end

  it "renders heading" do
    caption = provider.operating_name
    heading = "Provider details"
    expect(rendered).to have_heading("h1", "#{caption}#{heading}")
  end

  it "renders the provider" do
    expect(rendered).to have_selector("form")

    expect(rendered).to have_selector("input[name='provider[operating_name]']")
    expect(rendered).to have_selector("input[name='provider[legal_name]']")
    expect(rendered).to have_selector("input[name='provider[ukprn]']")
    expect(rendered).to have_selector("input[name='provider[urn]']")
    expect(rendered).to have_selector("input[name='provider[code]']")
  end

  it "renders the cancel link" do
    expect(rendered).to have_link("Cancel", href: provider_path(provider))
  end
  it "renders the back link" do
    expect(view.content_for(:breadcrumbs)).to have_back_link(provider_path(provider))
  end

  context "when goto is confirm" do
    let(:goto) { "confirm" }

    it "renders the back link" do
      expect(view.content_for(:breadcrumbs)).to have_back_link(provider_check_path(provider))
    end
  end

  context "with validation errors" do
    context "for school provider" do
      let(:provider) do
        provider = create(:provider, :unaccredited, :school)
        provider.operating_name = nil
        provider.ukprn = nil
        provider.urn = nil
        provider.code = nil
        provider.valid?
        provider
      end

      it "calls page_data with error" do
        expect(view).to have_received(:page_data).with({ error: true,
                                                         header: false,
                                                         subtitle: "Provider details",
                                                         title: provider.operating_name_was })
      end

      it "renders the error summary" do
        expect(view.content_for(:page_alerts)).to have_error_summary(
          "Enter operating name",
          "Enter UK provider reference number (UKPRN)",
          "Enter provider code",
          "Enter unique reference number (URN)"
        )
      end
    end

    context "for scitt provider" do
      let(:provider) do
        provider = create(:provider, :scitt)
        provider.operating_name = nil
        provider.ukprn = nil
        provider.urn = nil
        provider.code = nil
        provider.valid?
        provider
      end

      it "calls page_data with error" do
        expect(view).to have_received(:page_data).with({ error: true,
                                                         header: false,
                                                         subtitle: "Provider details",
                                                         title: provider.operating_name_was })
      end

      it "renders the error summary" do
        expect(view.content_for(:page_alerts)).to have_error_summary(
          "Enter operating name",
          "Enter UK provider reference number (UKPRN)",
          "Enter provider code",
          "Enter unique reference number (URN)"
        )
      end
    end

    context "for non school or non scitt provider" do
      let(:provider) do
        provider = create(:provider,
                          accreditation_status: [:unaccredited, :accredited].sample,
                          provider_type: (ProviderTypeEnum::ACCREDITED_PROVIDER_TYPES.keys - %i[scitt school]).sample)
        provider.operating_name = nil
        provider.ukprn = nil
        provider.urn = nil
        provider.code = nil
        provider.valid?
        provider
      end

      it "calls page_data with error" do
        expect(view).to have_received(:page_data).with({ error: true,
                                                         header: false,
                                                         subtitle: "Provider details",
                                                         title: provider.operating_name_was })
      end

      it "renders the error summary" do
        expect(view.content_for(:page_alerts)).to have_error_summary(
          "Enter operating name",
          "Enter UK provider reference number (UKPRN)",
          "Enter provider code",
        )
      end
    end
  end
end
