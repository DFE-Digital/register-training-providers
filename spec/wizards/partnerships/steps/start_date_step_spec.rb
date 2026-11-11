require "rails_helper"

RSpec.describe Partnerships::Steps::StartDateStep do
  subject(:step) { described_class.new(start_today:, start_date_day:, start_date_month:, start_date_year:) }

  let(:start_today) { "false" }
  let(:start_date_day) { 1 }
  let(:start_date_month) { 8 }
  let(:start_date_year) { 2024 }

  context "when the partnership starts on a chosen date" do
    it "builds the start date" do
      expect(step).to be_valid
      expect(step.start_date).to eq(Date.new(2024, 8, 1))
    end
  end

  context "when the partnership starts today" do
    let(:start_today) { "true" }
    let(:start_date_day) { nil }
    let(:start_date_month) { nil }
    let(:start_date_year) { nil }

    it "uses today's date" do
      expect(step).to be_valid
      expect(step.start_date).to eq(Time.zone.today)
      expect(step.start_date_day).to eq(Time.zone.today.day)
    end
  end

  context "when today is not chosen and no date is given" do
    let(:start_date_day) { nil }
    let(:start_date_month) { nil }
    let(:start_date_year) { nil }

    it "is invalid" do
      expect(step).not_to be_valid
      expect(step.errors[:start_date]).to include(
        I18n.t("activerecord.errors.models.partnerships/start_date_step.attributes.start_date.blank")
      )
    end
  end

  context "when the date cannot exist" do
    let(:start_date_month) { 13 }

    it "says so" do
      expect(step).not_to be_valid
      expect(step.errors[:start_date].join).to include("must be a real date")
    end
  end

  context "when no answer is given" do
    let(:start_today) { nil }

    it "is invalid" do
      expect(step).not_to be_valid
      expect(step.errors[:start_today]).to include(
        I18n.t("activerecord.errors.models.partnerships/start_date_step.attributes.start_today.inclusion")
      )
    end
  end
end
