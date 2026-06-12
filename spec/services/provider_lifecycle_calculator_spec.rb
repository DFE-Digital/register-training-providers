RSpec.describe ProviderLifecycleCalculator do
  subject(:result) { described_class.call(academic_years) }

  # NOTE: the specific date here is not important, just that it is after the end of the last academic year being tested against
  around do |example|
    Timecop.freeze(Date.new(2025, 8, 1)) do
      example.run
    end
  end

  let(:academic_years) { [year_2019, year_2020, year_2021, year_2022, year_2023, year_2024, year_2025_current] }

  let(:year_2019) { create(:academic_year, academic_year: 2019) }
  let(:year_2020) { create(:academic_year, academic_year: 2020) }
  let(:year_2021) { create(:academic_year, academic_year: 2021) }
  let(:year_2022) { create(:academic_year, academic_year: 2022) }
  let(:year_2023) { create(:academic_year, academic_year: 2023) }
  let(:year_2024) { create(:academic_year, academic_year: 2024) }
  let(:year_2025_current) { create(:academic_year, academic_year: 2025) }

  context "when there are no academic years" do
    let(:academic_years) { [] }

    it do
      expect(result).to eq(
        onboarded_at: nil,
        first_active_at: nil,
        inactive_periods: [],
      )
    end
  end

  context "when academic years are consecutive up to the current academic year" do
    it do
      expect(result).to eq(
        onboarded_at: Date.new(2019, 8, 1),
        first_active_at: Date.new(2019, 8, 1),
        inactive_periods: [],
      )
    end
  end

  context "when there is a single historical gap and an ongoing inactive period" do
    let(:academic_years) { [year_2019, year_2022] }

    it do
      expect(result).to eq(
        onboarded_at: Date.new(2019, 8, 1),
        first_active_at: Date.new(2019, 8, 1),
        inactive_periods: [
          {
            start_date: Date.new(2020, 8, 1),
            end_date: Date.new(2022, 7, 31),
            reason_for_inactive: "None given",
          },
          {
            start_date: Date.new(2023, 8, 1),
            end_date: nil,
            reason_for_inactive: "None given",
          },
        ],
      )
    end
  end

  context "when there are multiple historical gaps" do
    let(:academic_years) { [year_2019, year_2021, year_2025_current] }

    it do
      expect(result).to eq(
        onboarded_at: Date.new(2019, 8, 1),
        first_active_at: Date.new(2019, 8, 1),
        inactive_periods: [
          {
            start_date: Date.new(2020, 8, 1),
            end_date: Date.new(2021, 7, 31),
            reason_for_inactive: "None given",
          },
          {
            start_date: Date.new(2022, 8, 1),
            end_date: Date.new(2025, 7, 31),
            reason_for_inactive: "None given",
          },
        ],
      )
    end
  end

  context "when the provider has only one active academic year" do
    let(:academic_years) { [year_2019] }

    it do
      expect(result).to eq(
        onboarded_at: Date.new(2019, 8, 1),
        first_active_at: Date.new(2019, 8, 1),
        inactive_periods: [
          {
            start_date: Date.new(2020, 8, 1),
            end_date: nil,
            reason_for_inactive: "None given",
          },
        ],
      )
    end
  end

  context "when academic years are supplied out of order" do
    let(:academic_years) { [year_2021, year_2019, year_2020] }

    it do
      expect(result).to eq(
        onboarded_at: Date.new(2019, 8, 1),
        first_active_at: Date.new(2019, 8, 1),
        inactive_periods: [
          {
            start_date: Date.new(2022, 8, 1),
            end_date: nil,
            reason_for_inactive: "None given",
          },
        ],
      )
    end
  end
end
