# spec/helpers/academic_year_calculator_spec.rb
require "rails_helper"

RSpec.describe AcademicYearCalculator do
  around do |example|
    Timecop.freeze(Time.zone.local(2025, 9, 1)) do
      example.run
    end
  end

  describe ".current_academic_year" do
    it "returns 2025 for September 2025" do
      expect(described_class.current_academic_year).to eq(2025)
    end
  end

  describe ".month boundary behaviour" do
    it "shifts academic year correctly before and after August" do
      travel_cases = [
        [Time.zone.local(2025, 7, 31), 2024],
        [Time.zone.local(2025, 8, 1), 2025]
      ]

      travel_cases.each do |date, expected|
        Timecop.freeze(date) do
          expect(described_class.current_academic_year).to eq(expected)
        end
      end
    end
  end

  describe ".next_academic_year" do
    it "is current + 1" do
      expect(described_class.next_academic_year)
        .to eq(described_class.current_academic_year + 1)
    end
  end

  describe ".previous_academic_year" do
    it "is current - 1" do
      expect(described_class.previous_academic_year)
        .to eq(described_class.current_academic_year - 1)
    end
  end
end
