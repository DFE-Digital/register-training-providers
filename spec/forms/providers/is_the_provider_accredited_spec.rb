# spec/models/providers/is_the_provider_accredited_spec.rb
require "rails_helper"

RSpec.describe Providers::IsTheProviderAccredited, type: :model do
  describe "model attributes and behaviour" do
    subject { described_class.new(accreditation_status:) }

    context "with valid accreditation_status" do
      AccreditationStatusEnum::ACCREDITATION_STATUSES.each_value do |valid_status|
        let(:accreditation_status) { valid_status }

        it "is valid with #{valid_status}" do
          expect(subject).to be_valid
        end
      end
    end

    context "with invalid accreditation_status" do
      let(:accreditation_status) { "invalid_status" }

      it "is not valid" do
        expect(subject).not_to be_valid
        expect(subject.errors[:accreditation_status]).to include("is not included in the list")
      end
    end

    context "with nil accreditation_status" do
      let(:accreditation_status) { nil }

      it "is not valid" do
        expect(subject).not_to be_valid
        expect(subject.errors[:accreditation_status]).to include("Select if the provider is accredited")
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

  describe "#accreditation_status_options_for_radios" do
    subject { described_class.new }

    it "returns SelectOption objects with correct keys and values" do
      options = subject.accreditation_status_options_for_radios

      expect(options.size).to eq(AccreditationStatusEnum::ACCREDITATION_STATUSES.keys.size)

      options.each do |option|
        expect(option).to be_a(SelectOption)
        expect(option.key).to be_a(Symbol)
        expect(option.value).to eq(
          I18n.t("forms.providers.is_the_provider_accredited.accreditation_status.#{option.key}")
        )
      end
    end
  end
end
