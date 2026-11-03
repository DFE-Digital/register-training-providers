require "rails_helper"

RSpec.describe UserRoleEnum, type: :model do
  before do
    unless ActiveRecord::Base.connection.table_exists?(:user_role_enum_dummy_models)
      ActiveRecord::Schema.define do
        create_table :user_role_enum_dummy_models, force: true do |t|
          t.string :role
        end
      end
    end

    stub_const("UserRoleEnumDummyModel", Class.new(ApplicationRecord) do
      self.table_name = "user_role_enum_dummy_models"
      include UserRoleEnum
    end)
  end

  describe "enum definition" do
    it "defines role enum with correct values" do
      expect(UserRoleEnumDummyModel.roles).to eq(
        "reg" => "reg",
        "mr" => "mr",
        "bat" => "bat",
        "ro" => "ro"
      )
    end
  end

  describe "validation" do
    it "rejects an unknown role" do
      record = UserRoleEnumDummyModel.new(role: "invalid")

      expect(record).not_to be_valid
      expect(record.errors[:role]).to be_present
    end

    it "allows a blank role" do
      expect(UserRoleEnumDummyModel.new(role: nil)).to be_valid
    end
  end

  describe ".description_for" do
    it "returns the role description" do
      expect(UserRoleEnum.description_for("reg")).to eq("Service administration and full administrative access")
    end

    it "returns nil for a blank role" do
      expect(UserRoleEnum.description_for(nil)).to be_nil
    end
  end

  describe "#role_description" do
    it "delegates to description_for" do
      record = UserRoleEnumDummyModel.new(role: "mr")

      expect(record.role_description).to eq("Operational management of accredited providers, accreditation and associated partnerships")
    end
  end

  describe "#role_label" do
    [[:reg, "Register"],
     [:mr, "Market Regulation"],
     [:bat, "BAT Support"],
     [:ro, "Read-only"],
     [nil, "Not applicable"],
     ["", "Not applicable"],].each do |role, expected_label|
      it "returns #{expected_label.inspect} for role #{role.inspect}" do
        record = UserRoleEnumDummyModel.new(role:)
        expect(record.role_label).to eq(expected_label)
      end
    end
  end
end
