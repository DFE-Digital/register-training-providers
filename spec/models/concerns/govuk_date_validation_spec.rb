require "rails_helper"

RSpec.describe GovukDateValidation, type: :model do
  let(:test_class) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes
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

  describe "basic validation" do
    it "requires complete date when required" do
      expect(subject).not_to be_valid
      expect(subject.errors[:test_date]).to include("Enter test date")
    end

    it "validates missing components" do
      subject.test_date_month = 1
      subject.test_date_year = Date.current.year
      expect(subject).not_to be_valid
      expect(subject.errors[:test_date]).to include("Test date must include a day")
    end

    it "validates year format" do
      subject.test_date_day = 1
      subject.test_date_month = 1
      subject.test_date_year = 23
      expect(subject).not_to be_valid
      expect(subject.errors[:test_date]).to include("Year must include 4 numbers")
    end

    it "validates real dates" do
      subject.test_date_day = 30
      subject.test_date_month = 2
      subject.test_date_year = Date.current.year
      subject.send(:convert_date_components)
      expect(subject).not_to be_valid
      expect(subject.errors[:test_date]).to include("Test date must be a real date")
    end

    it "accepts valid dates" do
      subject.test_date_day = 1
      subject.test_date_month = 1
      subject.test_date_year = Date.current.year
      subject.send(:convert_date_components)
      expect(subject).to be_valid
    end
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
      expect(form.errors[:end_date]).to include("End date must be the same as or after")
    end
  end
end
