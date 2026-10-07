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

  ProviderTypeEnum::PROVIDER_TYPES.each_value do |valid_type|
    context "when provider_type is #{valid_type}" do
      let(:provider_type) { valid_type }

      context "and the provider is accredited" do
        let(:accredited_status_override) { true }

        it "is valid" do
          expect(subject).to be_valid
        end
      end

      context "and the provider is unaccredited" do
        let(:accredited_status_override) { false }

        it "is valid" do
          expect(subject).to be_valid
        end
      end
    end
  end

  context "when provider_type is not a known value" do
    let(:provider_type) { "invalid_type" }

    context "and the provider is accredited" do
      let(:accredited_status_override) { true }

      it "is invalid" do
        expect(subject).not_to be_valid
        expect(subject.errors[:provider_type]).to include("is not included in the list")
      end
    end

    context "and the provider is unaccredited" do
      let(:accredited_status_override) { false }

      it "is invalid" do
        expect(subject).not_to be_valid
        expect(subject.errors[:provider_type]).to include("is not included in the list")
      end
    end
  end
end
