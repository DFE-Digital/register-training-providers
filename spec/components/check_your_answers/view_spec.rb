require "rails_helper"

RSpec.describe CheckYourAnswers::View, type: :component do
  let(:rows) { [{ key: { text: "Question" }, value: { text: "Answer" } }] }
  let(:subtitle) { "Subtitle" }
  let(:caption) { "Caption" }
  let(:back_path) { "/some/path" }
  let(:save_button_text) { "Save" }
  let(:save_path) { "/save/path" }
  let(:cancel_path) { "/cancel/path" }
  let(:title) { "Check your answers" }

  before do
    render_inline(described_class.new(rows: rows, subtitle: subtitle, caption: caption, back_path: back_path,
                                      save_button_text: save_button_text, save_path: save_path, cancel_path: cancel_path, title: title))
  end

  it "renders the component with correct data" do
    expect(component).to have_content("Check your answers")
    expect(component).to have_content("Subtitle")
    expect(component).to have_content("Caption")

    expect(component).to have_link("Back", href: "/some/path")

    expect(component).to have_selector(".govuk-summary-list__row")

    expect(component).to have_button("Save")
    expect(component).to have_button_with(href: "/save/path")

    expect(component).to have_link("Cancel", href: "/cancel/path")
  end

  context "when there are no rows" do
    let(:rows) { [] }

    it "renders an empty summary list" do
      expect(component).not_to have_selector(".govuk-summary-list__row")
    end
  end
end
