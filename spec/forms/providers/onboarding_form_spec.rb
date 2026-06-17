require "rails_helper"

RSpec.describe Providers::OnboardingForm do
  subject(:form) { described_class.new }

  describe "validations" do
    it "requires a choice" do
      form.onboarded_at_date_choice = nil

      expect(form).not_to be_valid
      expect(form.errors[:onboarded_at_date_choice]).to be_present
    end

    it "does not require a date when choice is not 'other'" do
      form.onboarded_at_date_choice = "today"

      expect(form).to be_valid
    end

    it "requires a date when choice is 'other'" do
      form.onboarded_at_date_choice = "other"

      expect(form).not_to be_valid
      expect(form.errors[:onboarded_at_date]).to be_present
    end
  end

  describe "#onboarded_at" do
    before do
      allow(form).to receive(:predefined_dates).and_return(
        "today" => Date.new(2026, 1, 1),
        "yesterday" => Date.new(2025, 12, 31)
      )
    end

    context "when choice is predefined" do
      it "returns predefined date" do
        form.onboarded_at_date_choice = "today"

        expect(form.onboarded_at).to eq(Date.new(2026, 1, 1))
      end
    end

    context "when choice is other" do
      it "builds date from components" do
        form.onboarded_at_date_choice = "other"
        form.onboarded_at_date_day = 17
        form.onboarded_at_date_month = 6
        form.onboarded_at_date_year = 2025

        form.send(:convert_date_components)

        expect(form.onboarded_at).to eq(Date.new(2025, 6, 17))
      end
    end
  end

  describe "before_validation callback" do
    it "converts date components into a date" do
      form.onboarded_at_date_choice = "other"
      form.onboarded_at_date_day = 17
      form.onboarded_at_date_month = 6
      form.onboarded_at_date_year = 2025

      form.valid?

      expect(form.onboarded_at_date).to eq(Date.new(2025, 6, 17))
    end
  end

  describe ".model_name" do
    it "returns Provider for form builder compatibility" do
      expect(described_class.model_name.to_s).to eq("Provider")
    end
  end
end
