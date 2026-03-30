# spec/helpers/academic_year_helper_spec.rb
require "rails_helper"

RSpec.describe AcademicYearCalculator do
  describe ".current_academic_year" do
    context "when month is August or later" do
      it "returns the current year" do
        Timecop.freeze(Time.zone.local(2025, 8, 1)) do
          expect(described_class.current_academic_year).to eq(2025)
        end
      end
    end

    context "when month is before August" do
      it "returns the previous year" do
        Timecop.freeze(Time.zone.local(2025, 7, 31)) do
          expect(described_class.current_academic_year).to eq(2024)
        end
      end
    end
  end

  describe ".next_academic_year" do
    it "returns the next academic year" do
      Timecop.freeze(Time.zone.local(2025, 9, 1)) do
        expect(described_class.next_academic_year).to eq(2026)
      end
    end
  end

  describe ".previous_academic_year" do
    it "returns the previous academic year" do
      Timecop.freeze(Time.zone.local(2025, 9, 1)) do
        expect(described_class.previous_academic_year).to eq(2024)
      end
    end
  end
end
