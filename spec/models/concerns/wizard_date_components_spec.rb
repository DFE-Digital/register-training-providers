require "rails_helper"

RSpec.describe WizardDateComponents do
  let(:wizard_step_class) do
    Class.new do
      include DfE::Wizard::Step
      include WizardDateComponents
      include ActiveModel::Validations::Callbacks

      has_date_components :effective_on

      before_validation :convert_date_components

      def self.permitted_params
        %i[effective_on] + const_get(:PARAM_CONVERSION).keys
      end
    end
  end

  describe ".permitted_params" do
    it "permits the raw GOV.UK date params as well as the date attribute" do
      expected = [:effective_on, "effective_on(3i)", "effective_on(2i)", "effective_on(1i)"]

      expect(wizard_step_class.permitted_params).to eq(expected)
    end
  end

  describe "#initialize" do
    it "translates GOV.UK date params (string keys) onto the date components" do
      step = wizard_step_class.new(
        "effective_on(3i)" => 31,
        "effective_on(2i)" => 7,
        "effective_on(1i)" => 2026
      )

      expect(step.effective_on_day).to eq(31)
      expect(step.effective_on_month).to eq(7)
      expect(step.effective_on_year).to eq(2026)
    end

    it "translates GOV.UK date params (symbol keys) onto the date components" do
      step = wizard_step_class.new(
        "effective_on(3i)": 31,
        "effective_on(2i)": 7,
        "effective_on(1i)": 2026
      )

      expect(step.effective_on_day).to eq(31)
      expect(step.effective_on_month).to eq(7)
      expect(step.effective_on_year).to eq(2026)
    end

    it "passes day/month/year attributes through unchanged" do
      step = wizard_step_class.new(
        effective_on_day: 31,
        effective_on_month: 7,
        effective_on_year: 2026
      )

      expect(step.effective_on_day).to eq(31)
      expect(step.effective_on_month).to eq(7)
      expect(step.effective_on_year).to eq(2026)
    end

    it "materialises date components when only the date is given" do
      step = wizard_step_class.new(effective_on: Date.new(2026, 7, 31))

      expect(step.effective_on).to eq(Date.new(2026, 7, 31))
      expect(step.effective_on_day).to eq(31)
      expect(step.effective_on_month).to eq(7)
      expect(step.effective_on_year).to eq(2026)
    end

    it "does not override existing components when a date is also given" do
      step = wizard_step_class.new(
        effective_on: Date.new(2026, 7, 31),
        effective_on_day: 1,
        effective_on_month: 2,
        effective_on_year: 2030
      )

      expect(step.effective_on_day).to eq(1)
      expect(step.effective_on_month).to eq(2)
      expect(step.effective_on_year).to eq(2030)
    end

    it "passes wizard context through" do
      wizard = Object.new
      step = wizard_step_class.new(effective_on_day: 1, wizard: wizard, step_id: :effective_date)

      expect(step.wizard).to eq(wizard)
      expect(step.step_id).to eq(:effective_date)
    end

    it "builds the date from the translated components on validation" do
      step = wizard_step_class.new(
        "effective_on(3i)" => 31,
        "effective_on(2i)" => 7,
        "effective_on(1i)" => 2026
      )

      step.valid?

      expect(step.effective_on).to eq(Date.new(2026, 7, 31))
    end
  end
end
