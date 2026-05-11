require "rails_helper"

RSpec.describe AcademicYearHelper, type: :helper do
  describe "#academic_years_row" do
    subject { helper.academic_years_row(academic_years, false) }

    let(:academic_years) do
      [
        create(:academic_year, :current),
        create(:academic_year, :previous)
      ]
    end

    it "returns a hash with key and value" do
      expect(subject).to include(:key, :value)
      expect(subject[:key][:text]).to eq("Academic years")
    end

    it "renders a GOV.UK bullet list" do
      html = Nokogiri::HTML.fragment(subject[:value][:text])
      expect(html.css("ul.govuk-list--bullet")).to be_present
      expect(html.css("li").count).to eq(academic_years.size)
    end

    it "includes each academic year formatted text" do
      academic_years.each do |ay|
        expect(subject[:value][:text]).to include("#{ay.start_year} to #{ay.end_year}")
      end
    end
  end

  describe "#academic_years_html" do
    it "shows placeholder when empty" do
      expect(helper.academic_years_html([], false))
        .to include("No academic years")
    end

    it "renders a single list without a bullet list when 1 item only" do
      years = [
        create(:academic_year, :current),
      ]

      html = helper.academic_years_html(years, true)

      expect(html.scan("<ul").size).to eq(1)
      expect(html).not_to include("More academic years")
    end

    it "renders a single list when 3 or fewer items" do
      years = [
        create(:academic_year, :current),
        create(:academic_year, :previous)
      ]

      html = helper.academic_years_html(years, true)

      expect(html.scan("<ul").size).to eq(1)
      expect(html).not_to include("More academic years")
    end

    it "splits into primary list and details when more than 3 items" do
      years = create_list(:academic_year, 5, :previous)

      html = helper.academic_years_html(years, true)

      expect(html.scan("<ul").size).to eq(2)
      expect(html).to include("More academic years")

      years.each do |year|
        expect(html).to include("#{year.start_year} to #{year.end_year}")
      end
    end
  end

  describe "#display_academic_year" do
    subject(:result) { helper.display_academic_year(academic_year) }

    let(:academic_year) { create(:academic_year, academic_year: AcademicYearCalculator.previous_academic_year - 1) }

    it "formats the academic year range" do
      expect(subject).to eq("#{academic_year.start_year} to #{academic_year.end_year}")
    end

    context "when current" do
      let(:academic_year) { create(:academic_year, :current) }

      it "adds current label" do
        expect(subject).to include("current")
      end
    end

    context "when next" do
      let(:academic_year) { create(:academic_year, :next) }

      it "adds next label" do
        expect(subject).to include("next")
      end
    end

    context "when previous (last)" do
      let(:academic_year) { create(:academic_year, :previous) }

      it "adds last label" do
        expect(subject).to include("last")
      end
    end
  end

  describe "#academic_year_helper_text" do
    subject { helper.academic_year_helper_text(academic_year) }

    let(:academic_year) { create(:academic_year, :current) }

    it "formats academic year helper text correctly" do
      expect(subject).to eq("Starts on 1 August #{academic_year.start_year}, ends on 31 July #{academic_year.end_year}")
    end
  end

  describe "#academic_years_label" do
    subject { helper.academic_years_label(academic_years) }

    let(:current_year) { create(:academic_year, :current) }
    let(:next_year) { create(:academic_year, :next) }
    let(:previous_year) { create(:academic_year, :previous) }
    let(:other_year) { create(:academic_year, academic_year: AcademicYearCalculator.previous_academic_year - 1) }

    let(:academic_years) { [current_year, next_year, previous_year, other_year] }

    it "returns a hash indexed by start_year with formatted values" do
      expect(subject).to match(
        current_year.start_year.to_s => "#{current_year.start_year} to #{current_year.end_year} - current",
        next_year.start_year.to_s => "#{next_year.start_year} to #{next_year.end_year} - next",
        previous_year.start_year.to_s => "#{previous_year.start_year} to #{previous_year.end_year} - last",
        other_year.start_year.to_s => "#{other_year.start_year} to #{other_year.end_year}"
      )
    end
  end
end
