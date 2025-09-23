require "rails_helper"

RSpec.describe GovukDateValidation, type: :model do
  let(:test_class) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes
      include ActiveModel::Validations::Callbacks
      include GovukDateValidation

      attribute :test_date, :date
      attribute :test_date_day, :integer
      attribute :test_date_month, :integer
      attribute :test_date_year, :integer

      attribute :start_date, :date
      attribute :start_date_day, :integer
      attribute :start_date_month, :integer
      attribute :start_date_year, :integer

      attribute :end_date, :date
      attribute :end_date_day, :integer
      attribute :end_date_month, :integer
      attribute :end_date_year, :integer

      before_validation :convert_date_components

      validates_govuk_date :test_date, required: true, human_name: "test date"

      def self.model_name
        ActiveModel::Name.new(self, nil, "TestModel")
      end

    private

      def convert_date_components
        self.test_date = build_date_from_components(:test_date)
        self.start_date = build_date_from_components(:start_date)
        self.end_date = build_date_from_components(:end_date)
      end

      def build_date_from_components(date_field)
        year = send("#{date_field}_year")
        month = send("#{date_field}_month")
        day = send("#{date_field}_day")

        return nil unless year.present? && month.present? && day.present?

        begin
          Date.new(year, month, day)
        rescue ArgumentError
          nil
        end
      end
    end
  end

  subject { test_class.new }

  shared_examples "an invalid date form" do |scenario, expected_error|
    it "validates #{scenario}" do
      setup_invalid_date(scenario)
      subject.send(:convert_date_components) if scenario == :invalid_date
      expect(subject).not_to be_valid
      expect(subject.errors[:test_date]).to include(expected_error)
    end
  end

  shared_examples "a valid date form" do |scenario|
    it "accepts #{scenario}" do
      setup_valid_date(scenario)
      expect(subject).to be_valid
    end
  end

  def setup_invalid_date(scenario)
    case scenario
    when :incomplete_date
      # No setup needed - empty form
    when :missing_day
      subject.test_date_month = 1
      subject.test_date_year = Date.current.year
    when :invalid_year_format
      subject.test_date_day = 1
      subject.test_date_month = 1
      subject.test_date_year = 23
    when :invalid_date
      subject.test_date_day = 30
      subject.test_date_month = 2
      subject.test_date_year = Date.current.year
    end
  end

  def setup_valid_date(scenario)
    case scenario
    when :valid_date
      subject.test_date_day = 1
      subject.test_date_month = 1
      subject.test_date_year = Date.current.year
    end
  end

  describe "basic validation" do
    it_behaves_like "an invalid date form", :incomplete_date, "Enter test date"

    it_behaves_like "an invalid date form", :missing_day, "Test date must include a day"

    it_behaves_like "an invalid date form", :invalid_year_format, "Year must include 4 numbers"

    it_behaves_like "an invalid date form", :invalid_date, "Test date must be a real date"

    it_behaves_like "a valid date form", :valid_date
  end

  describe "temporal constraints" do
    let(:past_date_class) do
      Class.new(test_class) do
        validates_govuk_date :test_date, required: true, past: true, human_name: "past date"
      end
    end

    it "validates past dates" do
      form = past_date_class.new
      form.test_date_day = 1
      form.test_date_month = 1
      form.test_date_year = Date.current.year + 1
      form.send(:convert_date_components)
      expect(form).not_to be_valid
      expect(form.errors[:test_date]).to include("Past date must be in the past")
    end
  end

  describe "relative date validation" do
    let(:relative_date_class) do
      Class.new(test_class) do
        validates_govuk_date :start_date, required: true, human_name: "start date"
        validates_govuk_date :end_date, required: true, same_or_after: :start_date, human_name: "end date"
      end
    end

    it "validates end date is after start date" do
      form = relative_date_class.new
      form.start_date_day = 1
      form.start_date_month = 1
      form.start_date_year = Date.current.year
      form.end_date_day = 31
      form.end_date_month = 12
      form.end_date_year = Date.current.year - 1
      form.send(:convert_date_components)
      expect(form).not_to be_valid
      expect(form.errors[:end_date]).to include("The end date must be the same as or after 1 January #{Date.current.year} when the accreditation starts")
    end
  end
end
