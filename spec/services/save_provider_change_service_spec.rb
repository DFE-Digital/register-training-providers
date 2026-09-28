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

        it "still records the baseline, without applying it" do
          expect(Providers::ApplyProviderChangeJob).not_to receive(:perform_now)

          call_service

          expect(provider.provider_changes.baseline.sole).to have_attributes(
            value: "OLD",
            status: "completed"
          )
        end
      end
    end

    describe "the baseline it records" do
      it "captures the value the provider holds before the change" do
        call_service

        expect(provider.provider_changes.baseline.sole.value).to eq("OLD")
      end

      it "is dated from when the provider first became active" do
        allow(provider).to receive(:first_active_at).and_return(Date.new(2019, 8, 1))

        call_service

        expect(provider.provider_changes.baseline.sole.effective_on).to eq(Date.new(2019, 8, 1))
      end

      it "is written before the change, so a same-day change still sorts above it" do
        call_service

        history = provider.provider_changes.history.for_attribute("code").to_a

        expect(history.map(&:value)).to eq([value, "OLD"])
      end

      context "when saving the change itself fails" do
        def save_with(change_value)
          described_class.call(
            provider: provider,
            attribute_name: :code,
            attributes: { attribute_name: "code", effective_on: Date.current + 1.day, value: change_value },
            creator: creator
          )
        end

        it "raises, and still records the baseline, because it is still true" do
          expect { save_with(nil) }.to raise_error(ActiveRecord::RecordInvalid)

          expect(provider.provider_changes.baseline.sole.value).to eq("OLD")
        end

        it "does not duplicate the baseline when the save is retried" do
          expect { save_with(nil) }.to raise_error(ActiveRecord::RecordInvalid)

          save_with(value)

          expect(provider.provider_changes.baseline.count).to eq(1)
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

      it "does not record a second baseline" do
        call_service
        call_service

        expect(provider.provider_changes.baseline.count).to eq(1)
      end
    end

    context "when the attribute is optional and the value is blank" do
      let(:provider) { create(:provider, legal_name: "Old legal name") }
      let(:attribute_name) { :legal_name }
      let(:value) { "" }

      it "creates a pending provider change with a blank value" do
        provider_change = call_service

        expect(provider_change).to have_attributes(
          attribute_name: "legal_name",
          effective_on: effective_on,
          value: "",
          pending?: true
        )
      end

      context "when effective on is today" do
        let(:effective_on) { Date.current }

        it "applies the change and clears the provider legal name" do
          call_service

          expect(provider.reload.legal_name).to be_blank
        end
      end
    end
  end
end
