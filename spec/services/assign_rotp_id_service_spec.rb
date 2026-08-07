require "rails_helper"

RSpec.describe AssignRotpIdService do
  describe "#call" do
    let(:provider) do
      create(
        :provider
      )
    end

    subject(:service) { described_class.call(provider) }

    it "assigns a rotp_id to the provider" do
      service

      expect(provider.reload.rotp_id).to be_present
    end

    it "generates a unique rotp_id" do
      service

      expect(provider.reload.rotp_id).to start_with("RoTP-")
    end

    context "when the generated id already exists" do
      before do
        allow(RotpIdGeneratorService).to receive(:call)
          .and_return("RoTP-26ABC1DEF01", "RoTP-26XYZ2ABC01")

        create(
          :provider,
          rotp_id: "RoTP-26ABC1DEF01"
        )
      end

      it "retries with another id" do
        service

        expect(provider.reload.rotp_id)
          .to eq("RoTP-26XYZ2ABC01")

        expect(RotpIdGeneratorService)
          .to have_received(:call)
          .twice
      end
    end

    context "when the generated id keeps colliding" do
      before do
        allow(RotpIdGeneratorService)
          .to receive(:call)
          .and_return("RoTP-26ABC1DEF01")

        create(
          :provider,
          rotp_id: "RoTP-26ABC1DEF01"
        )
      end

      it "raises after reaching the maximum retry limit" do
        expect {
          described_class.call(provider)
        }.to raise_error(ActiveRecord::RecordNotUnique)

        (0..9).each do |attempt|
          expect(RotpIdGeneratorService)
          .to have_received(:call)
          .with(provider.operating_name, provider.onboarded_at, attempt)
        end

        expect(RotpIdGeneratorService)
          .to have_received(:call)
          .exactly(described_class::MAX_RETRIES).times
      end
    end
  end
end
