require "rails_helper"

RSpec.describe ProviderTypeValidator, type: :model do
  before do
    stub_const("DummyModel", Class.new do
      include ActiveModel::Model
      include ActiveModel::Validations

      attr_accessor :provider_type, :accredited_status_override

      validates :provider_type, provider_type: true

      def accredited?
        accredited_status_override
      end
    end)
  end

  subject { DummyModel.new(provider_type:, accredited_status_override:) }

  context "when accredited" do
    let(:accredited_status_override) { true }

    context "with valid provider types" do
      ProviderTypeEnum::ACCREDITED_PROVIDER_TYPES.each_value do |valid_type|
        let(:provider_type) { valid_type }

        it "is valid when provider_type is #{valid_type}" do
          expect(subject).to be_valid
        end
      end
    end

    context "with invalid provider types" do
      (ProviderTypeEnum::PROVIDER_TYPES.values - ProviderTypeEnum::ACCREDITED_PROVIDER_TYPES.values).each do |invalid_type|
        let(:provider_type) { invalid_type }
        it "is invalid when provider_type is #{invalid_type}" do
          expect(subject).not_to be_valid
          expect(subject.errors[:provider_type]).to include("is not included in the list")
        end
      end
    end
  end

  context "when unaccredited" do
    let(:accredited_status_override) { false }
    context "with valid provider types" do
      ProviderTypeEnum::UNACCREDITED_PROVIDER_TYPES.each_value do |valid_type|
        let(:provider_type) { valid_type }

        it "is valid when provider_type is #{valid_type}" do
          expect(subject).to be_valid
        end
      end
    end
    context "with invalid provider types" do
      (ProviderTypeEnum::PROVIDER_TYPES.values - ProviderTypeEnum::UNACCREDITED_PROVIDER_TYPES.values).each do |invalid_type|
        let(:provider_type) { invalid_type }
        it "is invalid when provider_type is #{invalid_type}" do
          expect(subject).not_to be_valid
          expect(subject.errors[:provider_type]).to include("is not included in the list")
        end
      end
    end
  end
end
