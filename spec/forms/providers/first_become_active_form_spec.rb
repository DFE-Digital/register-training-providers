require "rails_helper"

RSpec.describe Providers::FirstBecomeActiveForm do
  subject(:form) { described_class.new(attributes) }

  let(:onboarded_at) { Date.new(2024, 9, 1) }

  let(:base_attributes) do
    {
      onboarded_at:
    }
  end

  let(:attributes) { base_attributes }

  describe ".model_name" do
    it "returns Provider" do
      expect(described_class.model_name.name).to eq("Provider")
    end
  end

  describe ".i18n_scope" do
    it { expect(described_class.i18n_scope).to eq(:activerecord) }
  end

  describe ".additional_params" do
    it do
      expect(described_class.additional_params)
        .to eq([["onboarded_at", "onboarded_at"]])
    end
  end

  describe "#predefined_dates" do
    it do
      expect(form.predefined_dates).to eq(
        "same" => onboarded_at
      )
    end
  end

  describe "validations" do
    context "without a choice" do
      it "is invalid" do
        form.valid?

        expect(form.errors[:first_active_at_date_choice]).to be_present
      end
    end

    context "when the choice is same" do
      let(:attributes) do
        base_attributes.merge(
          first_active_at_date_choice: "same"
        )
      end

      it { expect(form).to be_valid }
    end

    context "when the choice is other" do
      let(:attributes) do
        base_attributes.merge(
          first_active_at_date_choice: "other"
        )
      end

      context "without a date" do
        it "is invalid" do
          form.valid?

          expect(form.errors[:first_active_at_date]).to be_present
        end
      end

      context "with a date" do
        let(:attributes) do
          super().merge(
            first_active_at_date_day: "15",
            first_active_at_date_month: "10",
            first_active_at_date_year: "2024"
          )
        end

        it { expect(form).to be_valid }
      end
    end
  end

  describe "#first_active_at" do
    context "when the choice is same" do
      let(:attributes) do
        base_attributes.merge(
          first_active_at_date_choice: "same"
        )
      end

      it "returns the onboarded_at date" do
        expect(form.first_active_at).to eq(onboarded_at)
      end
    end

    context "when the choice is other" do
      let(:attributes) do
        base_attributes.merge(
          first_active_at_date_choice: "other",
          first_active_at_date_day: "1",
          first_active_at_date_month: "11",
          first_active_at_date_year: "2024"
        )
      end

      it "returns the entered date" do
        form.valid?

        expect(form.first_active_at).to eq(Date.new(2024, 11, 1))
      end
    end
  end
end
