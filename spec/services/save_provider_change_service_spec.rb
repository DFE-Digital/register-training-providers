RSpec.describe SaveProviderChangeService do
  subject(:call_service) do
    described_class.call(
      provider:,
      attribute_name:,
      attributes:,
      creator:
    )
  end

  let(:provider) { create(:provider, code: "OLD") }
  let(:creator) { create(:user) }
  let(:attribute_name) { :code }
  let(:attributes) do
    {
      attribute_name:,
      effective_on:,
      value:
    }
  end
  let(:effective_on) { Date.current + 1.day }
  let(:value) { "ABC" }

  describe "#call" do
    context "when there is no pending change for the attribute" do
      it "creates a pending provider change" do
        expect { call_service }
          .to change { provider.provider_changes.pending.count }
          .by(1)
      end

      it "saves the change with the given attributes and creator" do
        provider_change = call_service

        expect(provider_change).to have_attributes(
          attribute_name: "code",
          effective_on: effective_on,
          value: value,
          pending?: true
        )
        expect(provider_change.creator).to eq(creator)
      end

      context "when effective on is today" do
        let(:effective_on) { Date.current }

        it "applies the change immediately" do
          expect(Providers::ApplyProviderChangeJob)
            .to receive(:perform_now)
            .with(an_instance_of(String))

          call_service
        end
      end

      context "when effective on is in the future" do
        it "does not apply the change immediately" do
          expect(Providers::ApplyProviderChangeJob).not_to receive(:perform_now)

          call_service
        end
      end
    end

    context "when there is an existing pending change for the attribute" do
      let!(:existing_change) do
        create(
          :provider_change,
          provider: provider,
          attribute_name: "code",
          value: "XXX",
          effective_on: Date.current + 2.days
        )
      end

      it "updates the existing change rather than creating a new one" do
        expect { call_service }
          .not_to(change { provider.provider_changes.pending.count })
      end

      it "saves the new attributes onto the existing change" do
        call_service

        expect(existing_change.reload).to have_attributes(
          value:,
          effective_on:
        )
      end
    end
  end
end
