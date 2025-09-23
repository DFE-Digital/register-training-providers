require "rails_helper"

RSpec.describe AccreditationForm, type: :model do
  let(:provider) { create(:provider, :hei) }
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
      form = described_class.new(valid_attributes.merge(
                                   end_date_day: 31,
                                   end_date_month: 12,
                                   end_date_year: Date.current.year - 4
                                 ))
      expect(form).not_to be_valid
      expect(form.errors[:end_date]).to be_present
    end

    it "allows missing end date" do
      subject.end_date_day = nil
      subject.end_date_month = nil
      subject.end_date_year = nil
      expect(subject).to be_valid
    end

    context "accreditation number format validation" do
      context "for HEI provider" do
        let(:provider) { create(:provider, :hei) }

        it "accepts valid HEI number starting with 1" do
          form = described_class.new(valid_attributes.merge(number: "1234", provider_type: "hei"))
          expect(form).to be_valid
        end

        it "rejects number starting with 5" do
          form = described_class.new(valid_attributes.merge(number: "5678", provider_type: "hei"))
          expect(form).not_to be_valid
          expect(form.errors[:number]).to include("Enter a valid accredited provider number - it must be 4 digits starting with a 1, like 1234")
        end
      end

      context "for SCITT provider" do
        let(:provider) { create(:provider, :scitt, :accredited) }

        it "accepts valid SCITT number starting with 5" do
          form = described_class.new(valid_attributes.merge(provider_id: provider.id, provider_type: "scitt", number: "5678"))
          expect(form).to be_valid
        end

        it "rejects number starting with 1" do
          form = described_class.new(valid_attributes.merge(provider_id: provider.id, provider_type: "scitt", number: "1234"))
          expect(form).not_to be_valid
          expect(form.errors[:number]).to include("Enter a valid accredited provider number - it must be 4 digits starting with a 5, like 5678")
        end
      end

      context "for School provider" do
        let(:provider) { create(:provider, :school, :unaccredited) }

        it "accepts valid school number starting with 5" do
          form = described_class.new(valid_attributes.merge(provider_id: provider.id, provider_type: "school", number: "5678"))
          expect(form).to be_valid
        end

        it "rejects number starting with 1" do
          form = described_class.new(valid_attributes.merge(provider_id: provider.id, provider_type: "school", number: "1234"))
          expect(form).not_to be_valid
          expect(form.errors[:number]).to include("Enter a valid accredited provider number - it must be 4 digits starting with a 5, like 5678")
        end
      end

      it "rejects non-numeric values" do
        form = described_class.new(valid_attributes.merge(number: "abcd"))
        expect(form).not_to be_valid
      end

      it "rejects numbers with wrong length" do
        form = described_class.new(valid_attributes.merge(number: "12345"))
        expect(form).not_to be_valid
      end
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
end
