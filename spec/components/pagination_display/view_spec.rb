require "rails_helper"

RSpec.describe PaginationDisplay::View, type: :component do
  before do
    @result = render_inline(described_class.new(pagy: pagy))
  end

  context "when there are less than 26 items" do
    let(:pagy) { Pagy.new(count: 25) }

    it "does not render" do
      expect(rendered_content).to be_empty
    end
  end

  context "when there are 26 or more items" do
    context "on first page" do
      let(:pagy) { Pagy.new(count: 26) }

      it "renders the pagination" do
        expect(rendered_content).to have_css(".govuk-pagination")
      end

      it "renders the pagination display summary" do
        expect(rendered_content).to have_text("Showing 1 to 25 of 26 results")
      end
    end

    context "on last page" do
      let(:pagy) { Pagy.new(count: 26, page: 2) }

      it "renders the pagination" do
        expect(rendered_content).to have_css(".govuk-pagination")
      end

      it "renders the pagination display summary" do
        expect(rendered_content).to have_text("Showing 26 to 26 of 26 results")
      end
    end
  end
end
