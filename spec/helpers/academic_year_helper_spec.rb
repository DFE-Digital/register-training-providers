require "rails_helper"

RSpec.describe AcademicYearHelper, type: :helper do
  def build_years(count)
    base = AcademicYearCalculator.current_academic_year

    (0...count).map do |i|
      build(:academic_year, academic_year: base - i)
    end
  end

  describe "#academic_years_row" do
    let(:academic_years) do
      [
        build(:academic_year, :previous),
        build(:academic_year, :current)
      ]
    end

    it "returns key/value structure" do
      result = helper.academic_years_row(academic_years, false)

      expect(result.keys).to contain_exactly(:key, :value)
      expect(result[:key][:text]).to eq("Academic years")
    end

    it "renders a bullet list when use_details is false" do
      result = helper.academic_years_row(academic_years, false)
      html = result[:value][:text]

      expect(html).to include("govuk-list", "govuk-list--bullet")
      expect(html).to include("<ul")
      expect(html).to include("<li")
    end

    it "renders all academic years in output" do
      result = helper.academic_years_row(academic_years, false)
      html = result[:value][:text]

      academic_years.each do |year|
        expect(html).to include(year.duration.begin.year.to_s)
        expect(html).to include(year.duration.end.year.to_s)
      end
    end
  end

  describe "#academic_years_html" do
    it "shows placeholder when empty" do
      expect(helper.academic_years_html([], false))
        .to include("No academic years")
    end

    it "renders a single list when 3 or fewer items" do
      html = helper.academic_years_html(build_years(3), true)

      expect(html.scan("<ul").size).to eq(1)
      expect(html).not_to include("More academic years")
    end

    it "splits into primary list and details when more than 3 items" do
      html = helper.academic_years_html(build_years(6), true)

      expect(html.scan("<ul").size).to eq(2)
      expect(html).to include("More academic years")
      expect(html).to include("<details")
    end
  end

  describe "grouping behaviour (slice of 3)" do
    it "keeps first 3 items in primary list and rest in details" do
      years = build_years(8)

      html = helper.academic_years_html(years, true)

      primary = years.first(3)
      overflow = years.drop(3)

      primary.each do |year|
        expect(html).to include(year.duration.begin.year.to_s)
      end

      overflow.each do |year|
        expect(html).to include(year.duration.begin.year.to_s)
      end
    end

    it "does not drop any academic years during grouping" do
      years = build_years(8)

      html = helper.academic_years_html(years, true)

      years.each do |year|
        expect(html).to include(year.duration.begin.year.to_s)
      end
    end
  end

  describe "#display_academic_year" do
    let(:academic_year) do
      build(:academic_year, academic_year: 2023)
    end

    it "formats year range correctly" do
      expect(helper.display_academic_year(academic_year))
        .to include("2023 to 2024")
    end

    it "adds label when present" do
      allow(academic_year).to receive(:next?).and_return(true)

      expect(helper.display_academic_year(academic_year))
        .to include("next")
    end

    it "orders multiple labels correctly" do
      allow(academic_year).to receive(:current?).and_return(true)
      allow(academic_year).to receive(:next?).and_return(true)

      expect(helper.display_academic_year(academic_year))
        .to eq("2023 to 2024 - current - next")
    end
  end

  describe "#academic_year_helper_text" do
    let(:academic_year) do
      build(:academic_year, academic_year: 2023)
    end

    it "formats helper text correctly" do
      expect(helper.academic_year_helper_text(academic_year))
        .to eq("Starts on 1 August 2023, ends on 31 July 2024")
    end
  end
end
