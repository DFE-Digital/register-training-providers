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

  subject(:component_instance) do
    described_class.new(
      rows: rows,
      subtitle: subtitle,
      caption: caption,
      back_path: back_path,
      save_button_text: save_button_text,
      save_path: save_path,
      cancel_path: cancel_path,
      title: title
    )
  end

  describe "rendered output" do
    subject(:rendered_component) { render_inline(component_instance) }

    it "renders summary list rows" do
      expect(rendered_component).to have_selector(".govuk-summary-list__row")
    end

    it "renders save button with correct text" do
      expect(rendered_component).to have_button(save_button_text)
    end

    it "renders cancel link" do
      expect(rendered_component).to have_link("Cancel", href: cancel_path)
    end

    context "when rows are empty" do
      let(:rows) { [] }

      it "renders no summary list rows" do
        expect(rendered_component).not_to have_selector(".govuk-summary-list__row")
      end
    end
  end
end
