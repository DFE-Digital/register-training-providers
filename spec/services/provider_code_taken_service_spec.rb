require "rails_helper"

RSpec.describe ProviderCodeTakenService do
  subject do
    described_class.call(code:, effective_on:)
  end

  let(:code) { "ABC" }
  let(:effective_on) { Date.new(2026, 9, 1) }

  describe "#call" do
    context "when a kept provider already has the code" do
      before do
        create(:provider, code:)
      end

      it "returns true" do
        expect(subject).to be(true)
      end
    end

    context "when a provider change already reserves the code for the effective date" do
      before do
        create(
          :provider_change,
          attribute_name: "code",
          value: code,
          effective_on: effective_on
        )
      end

      it "returns true" do
        expect(subject).to be(true)
      end
    end

    context "when the code exists in a provider change for a different date" do
      before do
        create(
          :provider_change,
          attribute_name: "code",
          value: code,
          effective_on: effective_on + 1.year
        )
      end

      it "returns false" do
        expect(subject).to be(false)
      end
    end

    context "when the code exists in a change for a different attribute" do
      before do
        create(
          :provider_change,
          attribute_name: "name",
          value: code,
          effective_on: effective_on
        )
      end

      it "returns false" do
        expect(subject).to be(false)
      end
    end

    context "when the code has not been taken" do
      it "returns false" do
        expect(subject).to be(false)
      end
    end
  end
end
