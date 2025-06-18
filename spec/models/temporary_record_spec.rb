require "rails_helper"

RSpec.describe TemporaryRecord, type: :model do
  let(:creator) { create(:user) }
  let(:user_data) { { "first_name" => "Jane", "last_name" => "Doe", "email" => "jane@example.com" } }

  subject do
    create(:temporary_record,
           record_type: "User",
           data: user_data,
           created_by: creator.id,
           expires_at: 1.hour.from_now,
           purpose: "check_your_answers")
  end

  describe "associations" do
    it { is_expected.to belong_to(:creator).class_name("User").with_foreign_key(:created_by) }
  end

  describe "enum purpose" do
    it do
      expect(subject).to define_enum_for(:purpose)
        .with_values(
          check_your_answers: "check_your_answers",
        )
        .backed_by_column_of_type(:string)
    end
  end

  describe "#expired?" do
    it "returns false if expires_at in future" do
      expect(subject.expired?).to eq(false)
    end

    it "returns true if expires_at in past" do
      subject.expires_at = 1.hour.ago
      expect(subject.expired?).to eq(true)
    end
  end

  describe ".expired scope" do
    before do
      create(:temporary_record, expires_at: 1.hour.ago)
      create(:temporary_record, expires_at: 1.hour.from_now)
    end

    it "returns only expired records" do
      expect(TemporaryRecord.expired.count).to eq(1)
    end
  end

  describe "#rehydrate" do
    it "returns a new instance of the stored model with data" do
      rehydrated = subject.rehydrate
      expect(rehydrated).to be_a(User)
      expect(rehydrated.first_name).to eq("Jane")
      expect(rehydrated.last_name).to eq("Doe")
      expect(rehydrated.email).to eq("jane@example.com")
    end
  end
end
