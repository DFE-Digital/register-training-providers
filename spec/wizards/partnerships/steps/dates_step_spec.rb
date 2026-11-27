require "rails_helper"

RSpec.describe Partnerships::Steps::DatesStep do
  subject(:step) { described_class.new(start_date_day:, start_date_month:, start_date_year:) }

  let(:start_date_day) { 1 }
  let(:start_date_month) { 8 }
  let(:start_date_year) { 2024 }

  it "builds the start date from the date components" do
    expect(step).to be_valid
    expect(step.start_date).to eq(Date.new(2024, 8, 1))
  end

  it "does not require an end date" do
    expect(step).to be_valid
    expect(step.end_date).to be_nil
  end

  context "when the start date is blank" do
    let(:start_date_day) { nil }
    let(:start_date_month) { nil }
    let(:start_date_year) { nil }

    it "is invalid" do
      expect(step).not_to be_valid
      expect(step.errors[:start_date]).to include(
        I18n.t("activerecord.errors.models.partnerships/dates_step.attributes.start_date.blank")
      )
    end
  end

  context "when the start date is not a real date" do
    let(:start_date_month) { 13 }

    it "is invalid" do
      expect(step).not_to be_valid
      expect(step.errors[:start_date]).to be_present
    end
  end

  describe ".permitted_params" do
    it "permits the date components as well as the dates" do
      expect(described_class.permitted_params).to include(
        :start_date,
        :end_date,
        "start_date(3i)",
        "start_date(2i)",
        "start_date(1i)",
        "end_date(3i)",
        "end_date(2i)",
        "end_date(1i)"
      )
    end
  end
end
