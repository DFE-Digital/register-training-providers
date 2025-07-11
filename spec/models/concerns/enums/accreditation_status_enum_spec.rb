require "rails_helper"

RSpec.describe AccreditationStatusEnum, type: :model do
  before do
    unless ActiveRecord::Base.connection.table_exists?(:dummy_models)
      ActiveRecord::Schema.define do
        create_table :dummy_models, force: true do |t|
          t.string :accreditation_status
        end
      end
    end

    stub_const("DummyModel", Class.new(ApplicationRecord) do
      self.table_name = "dummy_models"
      include AccreditationStatusEnum
    end)
  end

  describe "enum definition" do
    it "defines accreditation_status enum with correct values" do
      expect(DummyModel.accreditation_statuses).to eq(
        "accredited" => "accredited",
        "unaccredited" => "unaccredited"
      )
    end
  end

  describe "enum behaviour" do
    it "responds to accredited? and unaccredited?" do
      model = DummyModel.new(accreditation_status: :accredited)
      expect(model.accredited?).to be true
      expect(model.unaccredited?).to be false

      model.accreditation_status = :unaccredited
      expect(model.unaccredited?).to be true
      expect(model.accredited?).to be false
    end
  end
end
