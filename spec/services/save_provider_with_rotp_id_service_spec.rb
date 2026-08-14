require "rails_helper"

RSpec.describe SaveProviderWithRotpIdService do
  describe "#call" do
    let(:validate) { true }
    subject(:service) { described_class.call(provider, validate:) }

    context "when provider does not have a rotp_id" do
      let(:provider) { build(:provider) }

      it "assigns a rotp_id to the provider" do
        service

        expect(provider.reload.rotp_id).to be_present
      end

      it "generates a rotp_id with the expected format" do
        service

        expect(provider.reload.rotp_id)
          .to start_with("RoTP-")
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
          create(
            :provider,
            rotp_id: "RoTP-26ABC1DEF01"
          )

          allow(RotpIdGeneratorService)
            .to receive(:call)
            .and_return("RoTP-26ABC1DEF01")
        end

        it "raises after reaching the maximum retry limit" do
          expect {
            service
          }.to raise_error(ActiveRecord::RecordInvalid)

          expect(RotpIdGeneratorService)
            .to have_received(:call)
            .exactly(described_class::MAX_RETRIES).times
        end
      end

      context "when validate is set to false" do
        let(:validate) { false }

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
            create(
              :provider,
              rotp_id: "RoTP-26ABC1DEF01"
            )

            allow(RotpIdGeneratorService)
              .to receive(:call)
              .and_return("RoTP-26ABC1DEF01")
          end

          it "raises after reaching the maximum retry limit" do
            expect {
              service
            }.to raise_error(ActiveRecord::RecordNotUnique)

            expect(RotpIdGeneratorService)
              .to have_received(:call)
              .exactly(described_class::MAX_RETRIES).times
          end
        end
      end
    end

    context "when provider already has a rotp_id" do
      let(:provider) do
        build(
          :provider,
          rotp_id: "RoTP-26ABC1DEF01"
        )
      end

      it "does not generate a new rotp_id" do
        expect(RotpIdGeneratorService)
          .not_to receive(:call)

        service
      end

      it "saves the provider" do
        service

        expect(provider).to be_persisted
      end
    end
  end
end
