require "rails_helper"

RSpec.describe Partnerships::DatesForm, type: :model do
  describe "validations" do
    it "requires a start date" do
      form = described_class.new(
        start_date_day: nil,
        start_date_month: nil,
        start_date_year: nil
      )

      expect(form).not_to be_valid
      expect(form.errors[:start_date]).to include("Enter date the partnership started")
    end
  end

  describe ".from_dates" do
    DateValues = Struct.new(:start_date, :end_date, keyword_init: true)

    it "creates form from date object" do
      dates = DateValues.new(start_date: Date.new(2024, 9, 1), end_date: Date.new(2025, 8, 31))
      form = described_class.from_dates(dates)

      expect(form.start_date_day).to eq(1)
      expect(form.start_date_month).to eq(9)
      expect(form.start_date_year).to eq(2024)
    end
  end
end
