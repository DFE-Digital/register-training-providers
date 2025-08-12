require "rails_helper"

RSpec.describe "providers/_filters.html.erb", type: :view do
  let(:provider_filters) do
    {
      provider_types: ["hei", "other"],
      accreditation_statuses: ["accredited"],
      show_archived: ["show_archived_provider"]
    }
  end

  before do
    allow(view).to receive(:params).and_return(ActionController::Parameters.new(
                                                 filters: provider_filters
                                               ))

    def view.provider_filters
    end

    allow(view).to receive(:provider_filters).and_return(provider_filters)

    render partial: "providers/filters"
  end

  it "renders the filter container" do
    expect(rendered).to have_css("div.app-filter")
  end

  context "when filters are present" do
    it "shows the selected filters heading" do
      expect(rendered).to have_css("h2.govuk-heading-m", text: "Selected filters")
    end

    it "shows provider type selected filters" do
      expect(rendered).to have_css("h3", text: "Provider type")
      expect(rendered).to include("Higher education institution (HEI)")
      expect(rendered).to include("Other")
    end

    it "shows accreditation selected filters" do
      expect(rendered).to have_css("h3", text: "Accreditation type")
      expect(rendered).to include("Accredited")
    end

    it "shows archived providers selected filter" do
      expect(rendered).to have_css("h3", text: "Archived providers")
      expect(rendered).to include("Include archived providers")
    end

    it "renders the clear filters link" do
      expect(rendered).to have_link("Clear filters")
    end
  end

  it "renders the filters form" do
    expect(rendered).to have_css("form")
    expect(rendered).to have_button("Apply filters")
  end

  it "checks the correct checkboxes" do
    expect(rendered).to have_css("input[type=checkbox][value=hei][checked]")
    expect(rendered).not_to have_css("input[type=checkbox][value=scitt_or_school][checked]")
    expect(rendered).to have_css("input[type=checkbox][value=accredited][checked]")
    expect(rendered).not_to have_css("input[type=checkbox][value=unaccredited][checked]")
    expect(rendered).to have_css("input[type=checkbox][value=show_archived_provider][checked]")
  end
end
