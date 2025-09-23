require "rails_helper"

RSpec.describe AccreditationNumberValidator, type: :model do
  before do
    stub_const("DummyModel", Class.new do
      include ActiveModel::Model
      include ActiveModel::Validations

      attr_accessor :number, :provider_type

      validates :number, accreditation_number: true
    end)
  end

  describe "HEI provider validation" do
    let(:model) { DummyModel.new(provider_type: "hei") }

    context "with valid HEI number" do
      it "accepts numbers starting with 1" do
        model.number = "1234"
        expect(model).to be_valid
      end

      it "accepts 4-digit numbers starting with 1" do
        model.number = "1999"
        expect(model).to be_valid
      end
    end

    context "with invalid HEI number" do
      it "rejects numbers starting with 5" do
        model.number = "5234"
        expect(model).not_to be_valid
        expect(model.errors[:number]).to include("Enter a valid accredited provider number - it must be 4 digits starting with a 1, like 1234")
      end

      it "rejects numbers with wrong length" do
        model.number = "12345"
        expect(model).not_to be_valid
      end

      it "rejects non-numeric values" do
        model.number = "abcd"
        expect(model).not_to be_valid
      end
    end
  end

  describe "SCITT provider validation" do
    let(:model) { DummyModel.new(provider_type: "scitt") }

    context "with valid SCITT number" do
      it "accepts numbers starting with 5" do
        model.number = "5234"
        expect(model).to be_valid
      end

      it "accepts 4-digit numbers starting with 5" do
        model.number = "5999"
        expect(model).to be_valid
      end
    end

    context "with invalid SCITT number" do
      it "rejects numbers starting with 1" do
        model.number = "1234"
        expect(model).not_to be_valid
        expect(model.errors[:number]).to include("Enter a valid accredited provider number - it must be 4 digits starting with a 5, like 5234")
      end
    end
  end

  describe "School provider validation" do
    let(:model) { DummyModel.new(provider_type: "school") }

    context "with valid school number" do
      it "accepts numbers starting with 5" do
        model.number = "5234"
        expect(model).to be_valid
      end
    end

    context "with invalid school number" do
      it "rejects numbers starting with 1" do
        model.number = "1234"
        expect(model).not_to be_valid
        expect(model.errors[:number]).to include("Enter a valid accredited provider number - it must be 4 digits starting with a 5, like 5234")
      end
    end
  end

  describe "Unknown provider type validation" do
    let(:model) { DummyModel.new(provider_type: "unknown") }

    context "with valid generic number" do
      it "accepts numbers starting with 1" do
        model.number = "1234"
        expect(model).to be_valid
      end

      it "accepts numbers starting with 5" do
        model.number = "5234"
        expect(model).to be_valid
      end
    end

    context "with invalid generic number" do
      it "rejects numbers starting with other digits" do
        model.number = "2234"
        expect(model).not_to be_valid
        expect(model.errors[:number]).to include("Enter a valid accredited provider number - it must be 4 digits starting with a 1 or a 5")
      end
    end
  end

  describe "edge cases" do
    let(:model) { DummyModel.new(provider_type: "hei") }

    it "allows blank values (presence validation handled elsewhere)" do
      model.number = nil
      expect(model).to be_valid
    end

    it "allows empty strings (presence validation handled elsewhere)" do
      model.number = ""
      expect(model).to be_valid
    end
  end
end
