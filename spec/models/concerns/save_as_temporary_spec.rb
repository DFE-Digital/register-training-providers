require "rails_helper"

RSpec.describe SaveAsTemporary, type: :model do
  before do
    stub_const("DummyModel", Class.new do
      include ActiveModel::Model
      include ActiveModel::Attributes
      include SaveAsTemporary

      attribute :foo, :string
      attribute :bar, :integer

      attr_accessor :id

      def serializable_hash
        { "foo" => foo, "bar" => bar }
      end
    end)
  end

  let(:user) { create(:user) }

  it "saves a valid temporary record" do
    model = DummyModel.new(foo: "value", bar: 123)

    expect {
      model.save_as_temporary!(created_by: user, purpose: :check_your_answers)
    }.to change(TemporaryRecord, :count).by(1)

    record = TemporaryRecord.last
    expect(record.record_type).to eq("DummyModel")
    expect(record.data).to eq({ "foo" => "value", "bar" => 123 })
    expect(record.created_by).to eq(user.id)
    expect(record.purpose).to eq("check_your_answers")
  end

  it "upserts if same user and record_type" do
    model = DummyModel.new(foo: "initial", bar: 1)
    model.save_as_temporary!(created_by: user, purpose: :check_your_answers)

    expect {
      DummyModel.new(foo: "updated", bar: 2)
        .save_as_temporary!(created_by: user, purpose: :check_your_answers)
    }.not_to change(TemporaryRecord, :count)

    expect(TemporaryRecord.find_by(record_type: "DummyModel", created_by: user).data)
      .to eq({ "foo" => "updated", "bar" => 2 })
  end

  it "raises if model is invalid and responds to valid?" do
    model = DummyModel.new(foo: nil, bar: nil)

    def model.valid?
      false
    end

    expect {
      model.save_as_temporary!(created_by: user, purpose: :check_your_answers)
    }.to raise_error(ActiveRecord::RecordInvalid)

    expect(TemporaryRecord.count).to eq(0)
  end
end
