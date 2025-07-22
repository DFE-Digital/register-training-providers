require "rails_helper"

RSpec.describe ProviderTypeEnum, type: :model do
  before do
    unless ActiveRecord::Base.connection.table_exists?(:provider_type_enum_dummy_models)
      ActiveRecord::Schema.define do
        create_table :provider_type_enum_dummy_models, force: true do |t|
          t.string :provider_type
        end
      end
    end

    stub_const("ProviderTypeEnumDummyModel", Class.new(ApplicationRecord) do
      self.table_name = "provider_type_enum_dummy_models"
      include ProviderTypeEnum
    end)
  end

  describe "enum definition" do
    it "defines provider_type enum with correct values" do
      expect(ProviderTypeEnumDummyModel.provider_types).to eq(
        {
          "hei" => "hei",
          "scitt" => "scitt",
          "school" => "school",
          "other" => "other"
        }
      )
    end
  end

  describe "#provider_type_label" do
    [[:hei, "Higher education institution (HEI)"],
     [:scitt, "School-centred initial teacher training (SCITT)"],
     [:school, "School"],
     [:other, "Other"],
     [nil, "Not entered"],].each do |provider_type, expected_label|
      it "returns '#{expected_label}' for provider_type :#{provider_type}" do
        provider = ProviderTypeEnumDummyModel.new(provider_type:)
        expect(provider.provider_type_label).to eq(expected_label)
      end
    end
  end
end
