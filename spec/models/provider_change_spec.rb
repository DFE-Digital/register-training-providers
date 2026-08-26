require "rails_helper"

RSpec.describe ProviderChange, type: :model do
  subject(:provider_change) { build(:provider_change) }

  describe "associations" do
    it { is_expected.to belong_to(:provider) }
  end

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
