require "rails_helper"

RSpec.describe Providers::Accreditation, type: :model do
  let(:provider) { create(:provider) }
  let(:valid_attributes) do
    {
      number: "1234",
      provider_id: provider.id,
      start_date_day: 1,
      start_date_month: 1,
      start_date_year: Date.current.year - 3,
      end_date_day: 31,
      end_date_month: 12,
      end_date_year: Date.current.year + 2
    }
  end

  subject { described_class.new(valid_attributes) }

  describe "validations" do
    it "is valid with complete valid data" do
      expect(subject).to be_valid
    end

    it "requires a number" do
      subject.number = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:number]).to include("Enter an accredited provider number")
    end

    it "requires a start date" do
      subject.start_date_day = nil
      subject.start_date_month = nil
      subject.start_date_year = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:start_date]).to include("Enter date accreditation starts")
    end

    it "validates end date is after start date" do
      subject.end_date_year = Date.current.year - 4
      expect(subject).not_to be_valid
      expect(subject.errors[:end_date]).to be_present
    end

    it "allows missing end date" do
      subject.end_date_day = nil
      subject.end_date_month = nil
      subject.end_date_year = nil
      expect(subject).to be_valid
    end
  end

  describe "date conversion" do
    it "builds dates from components" do
      expect(subject.start_date).to be_a(Date)
      expect(subject.end_date).to be_a(Date)
    end

    it "returns nil for incomplete date components" do
      subject.end_date_day = nil
      subject.send(:convert_date_components)
      expect(subject.end_date).to be_nil
    end
  end

  describe "form integration" do
    it "provides model name for routing" do
      expect(described_class.model_name.name).to eq("Accreditation")
    end

    it "includes SaveAsTemporary for multi-step forms" do
      expect(subject).to respond_to(:save_as_temporary!)
    end
  end
end
