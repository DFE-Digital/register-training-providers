RSpec.describe ProviderCodeTakenService do
  subject(:code_taken) do
    described_class.call(code:, effective_on:, provider:)
  end

  let(:code) { "ABC" }
  let(:effective_on) { Date.new(2026, 9, 1) }
  let(:provider) { create(:provider, code: "123") }

  describe "#call" do
    context "when a kept provider already has the code" do
      before do
        create(:provider, code:)
      end

      it "returns true" do
        expect(code_taken).to be(true)
      end
    end

    context "when another provider has a pending code change effective on the requested date" do
      before do
        create(
          :provider_change,
          provider: create(:provider),
          attribute_name: "code",
          value: code,
          effective_on: effective_on
        )
      end

      it "returns true" do
        expect(code_taken).to be(true)
      end
    end

    context "when another provider has a pending code change effective after the requested date" do
      before do
        create(
          :provider_change,
          provider: create(:provider),
          attribute_name: "code",
          value: code,
          effective_on: effective_on + 1.day
        )
      end

      it "returns false" do
        expect(code_taken).to be(false)
      end
    end

    context "when another provider has a pending code change effective before the requested date" do
      before do
        create(
          :provider_change,
          provider: create(:provider),
          attribute_name: "code",
          value: code,
          effective_on: effective_on - 1.day
        )
      end

      it "returns true" do
        expect(code_taken).to be(true)
      end
    end

    context "when another provider has a pending change for a different attribute" do
      before do
        create(
          :provider_change,
          provider: create(:provider),
          attribute_name: "name",
          value: code,
          effective_on: effective_on
        )
      end

      it "returns false" do
        expect(code_taken).to be(false)
      end
    end

    context "when the provider itself has a pending code change" do
      before do
        create(
          :provider_change,
          provider: provider,
          attribute_name: "code",
          value: code,
          effective_on: effective_on
        )
      end

      it "returns false" do
        expect(code_taken).to be(false)
      end
    end

    context "when no provider has the code at the requested time" do
      it "returns false" do
        expect(code_taken).to be(false)
      end
    end
  end
end
