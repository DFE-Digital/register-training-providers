require "rails_helper"

RSpec.describe AcademicYearHelper, type: :helper do
  describe "#academic_years_row" do
    let(:academic_years) { build_list(:academic_year, 2) }

    it "returns a hash with :key and :value" do
      result = helper.academic_years_row(academic_years, false)

      expect(result).to include(:key, :value)
      expect(result[:key][:text]).to eq("Academic years")
    end

    it "renders a bullet list when use_details is false" do
      result = helper.academic_years_row(academic_years, false)
      html = result[:value][:text]

      expect(html).to include("govuk-list")
      expect(html).to include("govuk-list--bullet")
      expect(html).to include("<ul")
      expect(html).to include("<li")
    end

    it "wraps extra years in a <details> component when use_details is true" do
      years = build_list(:academic_year, 5)

      result = helper.academic_years_row(years, true)
      html = result[:value][:text]

      expect(html).to include("<ul").and include("<li")
      expect(html).to include("More academic years")
      expect(html.scan("<ul").size).to eq(2)
    end

    it "includes the formatted text for each academic year" do
      academic_years.each do |ay|
        allow(helper).to receive(:display_academic_year)
          .with(ay)
          .and_return("formatted #{ay.duration.begin.year}")
      end

      result = helper.academic_years_row(academic_years, false)
      html = result[:value][:text]

      academic_years.each do |ay|
        expect(html).to include("formatted #{ay.duration.begin.year}")
      end
    end
  end

  describe "#display_academic_year" do
    let(:start_year) { 2023 }
    let(:end_year)   { 2024 }
    let(:duration)   { Date.new(start_year, 8, 1)..Date.new(end_year, 7, 31) }

    let(:academic_year) do
      instance_double(
        "AcademicYear",
        duration: duration,
        current?: false,
        last?: false,
        next?: false
      )
    end

    it "formats the academic year range" do
      expect(helper.display_academic_year(academic_year))
        .to eq("#{start_year} to #{end_year}")
    end

    %i[current last next].each do |label|
      context "when #{label}" do
        before { allow(academic_year).to receive(:"#{label}?").and_return(true) }

        it "adds the #{label} label" do
          result = helper.display_academic_year(academic_year)
          expect(result).to include(label.to_s)
        end
      end
    end

    context "when multiple labels apply" do
      before do
        allow(academic_year).to receive(:current?).and_return(true)
        allow(academic_year).to receive(:next?).and_return(true)
      end

      it "adds all applicable labels in order" do
        result = helper.display_academic_year(academic_year)
        expect(result).to include("current")
        expect(result).to include("next")
        expect(result).to match(%r{#{start_year} to #{end_year} - current - next})
      end
    end
  end

  describe "#academic_year_helper_text" do
    let(:start_year) { 2023 }
    let(:end_year)   { 2024 }
    let(:duration)   { Date.new(start_year, 8, 1)..Date.new(end_year, 7, 31) }

    let(:academic_year) { instance_double("AcademicYear", duration:) }

    it "returns the correctly formatted text" do
      expect(helper.academic_year_helper_text(academic_year)).to eq(
        "Starts on 1 August #{start_year}, ends on 31 July #{end_year}"
      )
    end

    it "uses the beginning year of the duration" do
      expect(academic_year.duration.begin.year).to eq(start_year)

      result = helper.academic_year_helper_text(academic_year)
      expect(result).to include(start_year.to_s)
    end

    it "uses the ending year of the duration" do
      expect(academic_year.duration.end.year).to eq(end_year)

      result = helper.academic_year_helper_text(academic_year)
      expect(result).to include(end_year.to_s)
    end
  end
end
