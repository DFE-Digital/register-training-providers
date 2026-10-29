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

  describe "#role_label" do
    [[:reg, "Register"],
     [:mr, "Market Regulations"],
     [:bat, "BAT Support"],
     [:ro, "Read-only"],
     [nil, nil],
     ["", nil],].each do |role, expected_label|
      it "returns #{expected_label.inspect} for role #{role.inspect}" do
        record = UserRoleEnumDummyModel.new(role:)
        expect(record.role_label).to eq(expected_label)
      end
    end
  end
end
