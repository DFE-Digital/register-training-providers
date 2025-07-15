# spec/models/providers/is_the_provider_accredited_spec.rb
require "rails_helper"

RSpec.describe Providers::ProviderType, type: :model do
  describe "model attributes and behaviour" do
    let(:accreditation_status) { nil }
    let(:provider_type) { nil }
    subject { described_class.new(accreditation_status:, provider_type:) }

    context "with valid accreditation_status" do
      AccreditationStatusEnum::ACCREDITATION_STATUSES.each_value do |valid_status|
        context "when accreditation_status is #{valid_status}" do
          let(:accreditation_status) { valid_status }
          let(:provider_type) { :hei }

          it "is valid" do
            expect(subject).to be_valid
          end
        end
      end
    end

    context "with invalid accreditation_status" do
      let(:accreditation_status) { "invalid_status" }
      let(:provider_type) { ProviderTypeEnum::ACCREDITED_PROVIDER_TYPES.values.first }

      it "is not valid" do
        expect(subject).not_to be_valid
        expect(subject.errors[:accreditation_status]).to include("is not included in the list")
      end
    end

    context "with nil accreditation_status" do
      let(:accreditation_status) { nil }
      let(:provider_type) { :hei }

      it "is not valid" do
        expect(subject).not_to be_valid
        expect(subject.errors[:accreditation_status]).to include("Select if the provider is accredited")
      end
    end

    context "with valid accredited provider_type" do
      ProviderTypeEnum::ACCREDITED_PROVIDER_TYPES.each_value do |valid_type|
        context "when provider_type is #{valid_type}" do
          let(:provider_type) { valid_type }
          let(:accreditation_status) { AccreditationStatusEnum::ACCREDITED }

          it "is valid" do
            expect(subject).to be_valid
          end
        end
      end
    end

    context "with valid unaccredited provider_type" do
      ProviderTypeEnum::UNACCREDITED_PROVIDER_TYPES.each_value do |valid_type|
        context "when provider_type is #{valid_type}" do
          let(:provider_type) { valid_type }
          let(:accreditation_status) { AccreditationStatusEnum::UNACCREDITED }

          it "is valid" do
            expect(subject).to be_valid
          end
        end
      end
    end

    context "with invalid accredited provider_type" do
      ["invalid_type", "scitt"].each do |invalid_type|
        let(:provider_type) { invalid_type }
        let(:accreditation_status) { AccreditationStatusEnum::UNACCREDITED }

        it "is not valid" do
          expect(subject).not_to be_valid
          expect(subject.errors[:provider_type]).to include("is not included in the list")
        end
      end

      context "with invalid unaccredited provider_type" do
        ["invalid_type", "school"].each do |invalid_type|
          let(:provider_type) { invalid_type }
          let(:accreditation_status) { AccreditationStatusEnum::ACCREDITED }

          it "is not valid" do
            expect(subject).not_to be_valid
            expect(subject.errors[:provider_type]).to include("is not included in the list")
          end
        end

        context "with nil provider_type" do
          let(:provider_type) { nil }
          let(:accreditation_status) { AccreditationStatusEnum::ACCREDITATION_STATUSES.values.first }

          it "is not valid" do
            expect(subject).not_to be_valid
            expect(subject.errors[:provider_type]).to include("Select provider type")
          end
        end
      end
    end
  end

  describe ".model_name" do
    it "returns Provider as model name for form builder" do
      expect(described_class.model_name.name).to eq("Provider")
    end
  end

  describe ".i18n_scope" do
    it "returns :activerecord" do
      expect(described_class.i18n_scope).to eq(:activerecord)
    end
  end

  describe "#provider_type_options_for_radios" do
    subject { described_class.new(accreditation_status:) }
    context "when accredited" do
      let(:accreditation_status) { AccreditationStatusEnum::ACCREDITED }
      it "returns SelectOption objects with correct keys and values" do
        options = subject.provider_type_options_for_radios

        expect(options.size).to eq(ProviderTypeEnum::ACCREDITED_PROVIDER_TYPES.keys.size)

        options.each do |option|
          expect(option).to be_a(SelectOption)
          expect(option.key).to be_a(Symbol)
          expect(option.value).to eq(
            I18n.t("forms.providers.provider_type.provider_type.#{option.key}")
          )
        end
      end
    end

    context "when unaccredited" do
      let(:accreditation_status) { AccreditationStatusEnum::UNACCREDITED }
      it "returns SelectOption objects with correct keys and values" do
        options = subject.provider_type_options_for_radios

        expect(options.size).to eq(ProviderTypeEnum::UNACCREDITED_PROVIDER_TYPES.keys.size)

        options.each do |option|
          expect(option).to be_a(SelectOption)
          expect(option.key).to be_a(Symbol)
          expect(option.value).to eq(
            I18n.t("forms.providers.provider_type.provider_type.#{option.key}")
          )
        end
      end
    end
  end
end
