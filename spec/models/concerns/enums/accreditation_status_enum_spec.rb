require "rails_helper"

RSpec.describe AccreditationStatusEnum, type: :model do
  before do
    unless ActiveRecord::Base.connection.table_exists?(:accreditation_status_enum_dummy_models)
      ActiveRecord::Schema.define do
        create_table :accreditation_status_enum_dummy_models, force: true do |t|
          t.string :accreditation_status
        end
      end
    end

    stub_const("AccreditationStatusEnumDummyModel", Class.new(ApplicationRecord) do
      self.table_name = "accreditation_status_enum_dummy_models"
      include AccreditationStatusEnum
    end)
  end

  describe "enum definition" do
    it "defines accreditation_status enum with correct values" do
      expect(AccreditationStatusEnumDummyModel.accreditation_statuses).to eq(
        "accredited" => "accredited",
        "unaccredited" => "unaccredited"
      )
    end
  end
end
