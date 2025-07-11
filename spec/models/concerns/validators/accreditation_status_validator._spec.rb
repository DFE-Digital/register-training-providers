require "rails_helper"

RSpec.describe AccreditationStatusValidator, type: :model do
  before do
    stub_const("DummyModel", Class.new do
      include ActiveModel::Model
      include ActiveModel::Validations
      include AccreditationStatusValidator

      attr_accessor :accreditation_status
    end)
  end

  subject { DummyModel.new(accreditation_status:) }

  context "with valid accreditation status" do
    AccreditationStatusEnum::ACCREDITATION_STATUSES.each_value do |valid_status|
      let(:accreditation_status) { valid_status }

      it "is valid when accreditation_status is #{valid_status}" do
        expect(subject).to be_valid
      end
    end
  end

  context "with invalid accreditation status" do
    let(:accreditation_status) { "invalid_status" }

    it "is not valid" do
      expect(subject).not_to be_valid
      expect(subject.errors[:accreditation_status]).to include("is not included in the list")
    end
  end

  context "with nil accreditation status" do
    let(:accreditation_status) { nil }

    it "is not valid" do
      expect(subject).not_to be_valid
      expect(subject.errors[:accreditation_status]).to include("can't be blank")
    end
  end
end
