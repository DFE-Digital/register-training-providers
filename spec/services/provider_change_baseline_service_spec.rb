RSpec.describe ProviderChangeBaselineService do
  subject(:call_service) { described_class.call(provider:, attribute_name:) }

  let(:provider) { create(:provider, code: "OLD", first_active_at: Date.new(2019, 8, 1)) }
  let(:attribute_name) { "code" }

  describe "#call" do
    it "records the value the provider is holding now" do
      call_service

      expect(provider.provider_changes.baseline.sole).to have_attributes(
        attribute_name: "code",
        value: "OLD",
        effective_on: Date.new(2019, 8, 1),
        status: "completed",
        source: "baseline"
      )
    end

    it "records no creator, because nobody changed this value" do
      call_service

      expect(provider.provider_changes.baseline.sole.creator).to be_nil
    end

    it "is completed, so it is never re-applied" do
      call_service

      expect(provider.provider_changes.pending).to be_empty
    end

    it "is invisible to the pending value lookup used for code uniqueness" do
      call_service

      expect(
        ProviderChange.pending_value_change(attribute: "code", value: "OLD", effective_on: Date.current)
      ).to be_empty
    end

    it "records a baseline per attribute" do
      described_class.call(provider: provider, attribute_name: "code")
      described_class.call(provider: provider, attribute_name: "ukprn")

      expect(provider.provider_changes.baseline.pluck(:attribute_name))
        .to contain_exactly("code", "ukprn")
    end

    context "when a baseline already exists" do
      before { call_service }

      it "does not create a second one" do
        expect { call_service }.not_to(change { provider.provider_changes.baseline.count })
      end
    end

    context "when the provider already has a change for that attribute" do
      before do
        create(:provider_change, provider: provider, attribute_name: "code", value: "MID", status: :completed)
      end

      it "records nothing, rather than a period that may never have happened" do
        call_service

        expect(provider.provider_changes.baseline).to be_empty
      end

      it "leaves the existing change as the earliest record" do
        call_service

        expect(provider.provider_changes.history.for_attribute("code").first.value).to eq("MID")
      end
    end

    context "when the provider has only pending changes" do
      before do
        create(:provider_change, provider: provider, attribute_name: "code", value: "NEW", status: :pending)
      end

      it "still records the baseline" do
        call_service

        expect(provider.provider_changes.baseline.sole.value).to eq("OLD")
      end

      it "orders the pending change above it" do
        call_service

        expect(provider.provider_changes.history.for_attribute("code").map(&:status)).to eq(%w[pending completed])
      end
    end

    context "when the provider has a change for a different attribute" do
      before do
        create(:provider_change, :ukprn_change, provider: provider, status: :completed)
      end

      it "still records the baseline for this attribute" do
        call_service

        expect(provider.provider_changes.baseline.sole.value).to eq("OLD")
      end
    end

    context "when another request wins the race" do
      before do
        allow(provider.provider_changes).to receive(:create!).and_raise(ActiveRecord::RecordNotUnique)
      end

      it "treats the lost race as success, because the row now exists" do
        expect { call_service }.not_to raise_error
      end
    end

    context "when the attribute is not changeable" do
      it "refuses rather than reading an arbitrary provider attribute" do
        expect { described_class.call(provider: provider, attribute_name: "update!") }
          .to raise_error(ArgumentError, /not a changeable attribute/)
      end
    end

    context "when the provider has no recorded active date" do
      before { allow(provider).to receive(:first_active_at).and_return(nil) }

      it "falls back to the onboarded date" do
        allow(provider).to receive(:onboarded_at).and_return(Date.new(2018, 9, 1))

        call_service

        expect(provider.provider_changes.baseline.sole.effective_on).to eq(Date.new(2018, 9, 1))
      end

      it "falls back to the date the record was created when it was never onboarded" do
        allow(provider).to receive(:onboarded_at).and_return(nil)

        call_service

        expect(provider.provider_changes.baseline.sole.effective_on).to eq(provider.created_at.to_date)
      end
    end

    context "when the provider was onboarded before it first became active" do
      it "still prefers the active date, because that is the date it became active" do
        allow(provider).to receive_messages(
          first_active_at: Date.new(2021, 9, 1),
          onboarded_at: Date.new(2018, 9, 1)
        )

        call_service

        expect(provider.provider_changes.baseline.sole.effective_on).to eq(Date.new(2021, 9, 1))
      end
    end

    context "when the provider first became active in the future" do
      let(:provider) { create(:provider, code: "OLD", first_active_at: Date.current + 1.year) }

      it "clamps to today, so it cannot post-date the change it precedes" do
        call_service

        expect(provider.provider_changes.baseline.sole.effective_on).to eq(Date.current)
      end
    end
  end
end
