require "rails_helper"

RSpec.describe "providers/show.html.erb", type: :view do
  let(:provider) { build_stubbed(:provider, :school) }
  let(:goto) { nil }

  before do
    assign(:provider, provider)
    allow(view).to receive(:provider_page_data)

    render
  end

  it "calls provider_page_data" do
    expect(view).to have_received(:provider_page_data).with(provider)
  end

  it "renders heading" do
    expect(rendered).to have_heading("h2", "Provider details")
  end

  it "does not render the archive button for an active provider" do
    expect(rendered).not_to have_link("Archive provider", href: provider_archive_path(provider))
  end

  context "when the provider is inactive" do
    let(:provider) do
      build_stubbed(:provider, :school, inactive_periods: [{ "start_date" => 1.month.ago.to_date.to_s,
                                                             "end_date" => nil }])
    end

    it "renders the archive button" do
      expect(rendered).to have_link("Archive provider", href: provider_archive_path(provider))
    end
  end

  context "when the provider is offboarded" do
    let(:provider) do
      build_stubbed(:provider, :school, inactive_periods: [{ "start_date" => 1.month.ago.to_date.to_s,
                                                             "end_date" => nil,
                                                             "offboarded" => true }])
    end

    it "does not render the archive button" do
      expect(rendered).not_to have_link("Archive provider", href: provider_archive_path(provider))
    end
  end

  context "when the provider is archived" do
    let(:provider) { build_stubbed(:provider, :archived) }

    it "renders the restore button" do
      expect(rendered).to have_link("Restore", href: provider_restore_path(provider))
    end
    it "renders the delete link" do
      expect(rendered).to have_link("Delete", href: provider_delete_path(provider))
    end
  end

  it "renders the provider" do
    expect(rendered).to have_selector(".govuk-summary-list__key", text: "Provider type")
    expect(rendered).to have_selector(".govuk-summary-list__value", text: provider.provider_type_label)
    expect(rendered).to have_selector(".govuk-summary-list__key", text: "Accreditation status")
    expect(rendered).to have_selector(".govuk-summary-list__value", text: provider.accreditation_status_label)
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

  it "renders the back link" do
    expect(view.content_for(:breadcrumbs)).to have_back_link(providers_path)
  end
end
