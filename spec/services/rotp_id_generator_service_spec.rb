require "rails_helper"

RSpec.describe RotpIdGeneratorService do
  describe "#call" do
    let(:operating_name) { "Example Training Provider" }
    let(:onboarded_at) { Date.new(2026, 7, 31) }
    let(:attempt) { 0 }

    subject(:rotp_id) do
      described_class.call(
        operating_name,
        onboarded_at,
        attempt
      )
    end

    it "generates a RoTP ID in the expected format" do
      expect(rotp_id).to match(
        /\ARoTP-\d{2}[A-Z]\d[A-Z]{2}\d{2}\z/
      )
    end

    it "includes the onboarded year" do
      expect(rotp_id).to start_with("RoTP-26")
    end

    it "includes the onboarded month" do
      expect(rotp_id).to end_with("07")
    end

    it "generates the same ID for the same inputs" do
      first_id = described_class.call(
        operating_name,
        onboarded_at,
        attempt
      )

      second_id = described_class.call(
        operating_name,
        onboarded_at,
        attempt
      )

      expect(first_id).to eq(second_id)
    end

    it "generates different IDs for different providers" do
      first_id = described_class.call(
        "Example Training Provider",
        onboarded_at,
        attempt
      )

      second_id = described_class.call(
        "Another Training Provider",
        onboarded_at,
        attempt
      )

      expect(first_id).not_to eq(second_id)
    end

    it "generates a different candidate for a different attempt" do
      first = described_class.call(
        operating_name,
        onboarded_at,
        attempt
      )

      second = described_class.call(
        operating_name,
        onboarded_at,
        attempt + 1
      )

      expect(first).not_to eq(second)
    end
  end
end
