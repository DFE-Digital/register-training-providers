RSpec.describe ProviderChange, type: :model do
  subject(:provider_change) { build(:provider_change) }

  describe "associations" do
    it { is_expected.to belong_to(:provider) }
    it { is_expected.to belong_to(:creator).class_name("User").with_foreign_key(:created_by_id).optional }
  end

  it { is_expected.to be_audited }

  describe "enums" do
    it do
      expect(described_class.statuses).to eq(
        "pending" => "pending",
        "processing" => "processing",
        "completed" => "completed",
        "failed" => "failed"
      )
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:attribute_name) }
    it { is_expected.to validate_presence_of(:value) }
    it { is_expected.to validate_presence_of(:effective_on) }
  end

  describe ".for_attribute" do
    let!(:code_change) do
      create(:provider_change, attribute_name: "code")
    end

    let!(:name_change) do
      create(:provider_change, attribute_name: "name")
    end

    it "returns changes for the specified attribute" do
      expect(described_class.for_attribute("code")).to contain_exactly(code_change)
    end
  end

  describe ".effective_on_or_before" do
    let(:effective_on) { Date.new(2026, 9, 1) }

    let!(:before_change) do
      create(:provider_change, effective_on: effective_on - 1.day)
    end

    let!(:on_change) do
      create(:provider_change, effective_on:)
    end

    let!(:after_change) do
      create(:provider_change, effective_on: effective_on + 1.day)
    end

    it "returns changes effective on or before the specified date" do
      expect(described_class.effective_on_or_before(effective_on))
        .to contain_exactly(before_change, on_change)
    end
  end

  describe ".pending_value_change" do
    let(:effective_on) { Date.new(2026, 9, 1) }
    let(:value) { "ABC" }

    let!(:matching_change) do
      create(:provider_change, status: :pending, attribute_name: "code", value: value, effective_on: effective_on)
    end

    let!(:before_change) do
      create(:provider_change, status: :pending, attribute_name: "code", value: value, effective_on: effective_on - 1.day)
    end

    let!(:later_change) do
      create(:provider_change, status: :pending, attribute_name: "code", value: value, effective_on: effective_on + 1.day)
    end

    let!(:different_value_change) do
      create(:provider_change, status: :pending, attribute_name: "code", value: "XYZ", effective_on: effective_on)
    end

    let!(:different_attribute_change) do
      create(:provider_change, status: :pending, attribute_name: "name", value: value, effective_on: effective_on)
    end

    let!(:completed_change) do
      create(
        :provider_change,
        status: :completed,
        attribute_name: "code",
        value: value,
        effective_on: effective_on
      )
    end

    it "returns pending changes for the attribute and value effective on or before the specified date" do
      expect(
        described_class.pending_value_change(attribute: "code", value: value, effective_on: effective_on)
      ).to contain_exactly(matching_change, before_change)
    end
  end

  describe ".history" do
    let!(:old_change) do
      create(
        :provider_change,
        effective_on: Date.new(2025, 1, 1),
        created_at: 2.days.ago
      )
    end

    let!(:newer_change) do
      create(
        :provider_change,
        effective_on: Date.new(2025, 2, 1),
        created_at: 1.day.ago
      )
    end

    let!(:same_date_later_created_change) do
      create(
        :provider_change,
        effective_on: Date.new(2025, 2, 1),
        created_at: Time.current
      )
    end

    it "orders by effective date descending, then creation date descending" do
      expect(described_class.history).to eq(
        [
          same_date_later_created_change,
          newer_change,
          old_change
        ]
      )
    end
  end
end
