require "rails_helper"

RSpec.describe Providers::ApplyStatusChangeService, type: :service do
  subject(:transition) do
    described_class.call(
      provider:,
      new_status:,
      effective_on:,
      reasons:
    )
  end

  let(:effective_on) { Date.new(2027, 1, 15) }
  let(:new_status) { "inactive" }
  let(:reasons) { [] }

  def periods
    provider.reload.inactive_periods
  end

  context "when the provider is active" do
    let(:provider) { create(:provider) }

    context "when the new status is missing" do
      let(:new_status) { nil }

      it "is not a valid transition" do
        expect(transition).to be(false)
        expect(provider.errors[:base]).to include("Status cannot change from active to ")
      end

      it "leaves the periods untouched" do
        transition

        expect(periods).to be_empty
      end
    end

    context "when no date is supplied" do
      let(:effective_on) { nil }

      it "is not a valid transition" do
        expect(transition).to be(false)
      end

      it "leaves the periods untouched" do
        transition

        expect(periods).to be_empty
      end
    end

    context "when marking the provider as inactive" do
      let(:reasons) { ["No current cohorts"] }

      it "appends an open inactive period" do
        transition

        expect(periods).to contain_exactly(
          "start_date" => effective_on.to_s,
          "end_date" => nil,
          "reasons_for_inactive" => reasons
        )
      end
    end

    context "when marking the provider as offboarded" do
      let(:new_status) { "offboarded" }

      it "appends an open offboarded period" do
        transition

        expect(periods).to contain_exactly(
          "start_date" => effective_on.to_s,
          "end_date" => nil,
          "offboarded" => true
        )
      end
    end

    context "when the provider is already in the new status" do
      let(:new_status) { "active" }

      it "does not append a period" do
        transition

        expect(periods).to be_empty
      end
    end
  end

  context "when the provider is inactive" do
    let(:provider) do
      create(:provider,
             first_active_at: Date.new(2020, 1, 1),
             onboarded_at: Date.new(2020, 1, 1)).tap do |inactive_provider|
        inactive_provider.inactive_periods << {
          "start_date" => "2026-09-01",
          "end_date" => nil,
          "reasons_for_inactive" => ["No current cohorts"]
        }
        inactive_provider.save!
      end
    end

    context "when marking the provider as active" do
      let(:new_status) { "active" }

      it "closes the inactive period the day before the reactivation" do
        transition

        expect(periods).to contain_exactly(
          "start_date" => "2026-09-01",
          "end_date" => (effective_on - 1.day).to_s,
          "reasons_for_inactive" => ["No current cohorts"]
        )
      end

      context "when the reactivation is effective on the inactive period's start date" do
        let(:effective_on) { Date.new(2026, 9, 1) }

        it "closes the period on that day rather than before it" do
          transition

          expect(periods.sole["end_date"]).to eq("2026-09-01")
        end
      end
    end

    context "when marking the provider as offboarded" do
      let(:new_status) { "offboarded" }
      let(:reasons) { ["Financial viability"] }

      it "closes the inactive period and appends an open offboarded period" do
        transition

        expect(periods).to include(
          "start_date" => "2026-09-01",
          "end_date" => (effective_on - 1.day).to_s,
          "reasons_for_inactive" => ["No current cohorts"]
        )
        expect(periods).to include(
          "start_date" => effective_on.to_s,
          "end_date" => nil,
          "offboarded" => true,
          "reasons_for_inactive" => reasons
        )
      end
    end

    context "when the date is before the inactive period starts" do
      let(:new_status) { "active" }
      let(:effective_on) { Date.new(2026, 8, 31) }

      it "is not a valid transition" do
        expect(transition).to be(false)
        expect(provider.errors[:base].join).to match(/cannot be within or before the period/)
      end

      it "leaves the inactive period open" do
        transition

        expect(periods).to contain_exactly(
          "start_date" => "2026-09-01",
          "end_date" => nil,
          "reasons_for_inactive" => ["No current cohorts"]
        )
      end
    end
  end

  context "when the provider is offboarded" do
    let(:provider) do
      create(:provider,
             first_active_at: Date.new(2020, 1, 1),
             onboarded_at: Date.new(2020, 1, 1)).tap do |offboarded_provider|
        offboarded_provider.inactive_periods << {
          "start_date" => "2026-09-01",
          "end_date" => nil,
          "offboarded" => true,
          "reasons_for_inactive" => ["Financial viability"]
        }
        offboarded_provider.save!
      end
    end

    context "when marking the provider as active" do
      let(:new_status) { "active" }

      it "closes the offboarded period the day before the reactivation" do
        transition

        expect(periods).to contain_exactly(
          "start_date" => "2026-09-01",
          "end_date" => (effective_on - 1.day).to_s,
          "offboarded" => true,
          "reasons_for_inactive" => ["Financial viability"]
        )
      end
    end

    context "when marking the provider as inactive" do
      let(:new_status) { "inactive" }
      let(:reasons) { ["No current cohorts"] }

      it "closes the offboarded period and appends an open inactive period" do
        transition

        expect(periods).to include(
          "start_date" => "2026-09-01",
          "end_date" => (effective_on - 1.day).to_s,
          "offboarded" => true,
          "reasons_for_inactive" => ["Financial viability"]
        )
        expect(periods).to include(
          "start_date" => effective_on.to_s,
          "end_date" => nil,
          "reasons_for_inactive" => reasons
        )
        expect(periods).not_to include(
          "start_date" => effective_on.to_s,
          "end_date" => nil,
          "offboarded" => true
        )
      end
    end
  end

  context "when the provider fails validation at save" do
    let(:provider) do
      create(:provider, first_active_at: Date.new(2020, 1, 1), onboarded_at: Date.new(2020, 1, 1))
    end

    before do
      allow(provider).to receive(:save).and_return(false)
      allow(provider).to receive(:save!)
        .and_raise(StandardError, "save! must not replace the soft save")
    end

    it "returns false instead of raising" do
      expect(transition).to be(false)
    end

    it "leaves the periods untouched in the database" do
      transition

      expect(periods).to be_empty
    end
  end

  context "when the new status is not a transitionable status" do
    let(:provider) { create(:provider) }
    let(:new_status) { "archived" }

    it "is not a valid transition" do
      expect(transition).to be(false)
      expect(provider.errors[:base]).to include("Status cannot change from active to archived")
    end
  end

  context "when the provider has a closed inactive period" do
    let(:provider) do
      create(:provider,
             first_active_at: Date.new(2020, 1, 1),
             onboarded_at: Date.new(2020, 1, 1)).tap do |provider|
        provider.inactive_periods << {
          "start_date" => "2026-01-01",
          "end_date" => "2026-06-01"
        }
        provider.save!
      end
    end

    context "when the date falls inside the closed period" do
      let(:effective_on) { Date.new(2026, 3, 2) }

      it "is not a valid transition" do
        expect(transition).to be(false)
        expect(provider.errors[:base].join).to match(/cannot be within or before the period/)
      end

      it "leaves the periods untouched" do
        transition

        expect(periods).to contain_exactly(
          "start_date" => "2026-01-01",
          "end_date" => "2026-06-01"
        )
      end
    end

    context "when the date is the period's end date" do
      let(:effective_on) { Date.new(2026, 6, 1) }

      it "is not a valid transition" do
        expect(transition).to be(false)
      end
    end

    context "when the date is after the closed period" do
      let(:effective_on) { Date.new(2026, 6, 2) }

      it "appends an open inactive period" do
        transition

        expect(periods).to include(
          "start_date" => effective_on.to_s,
          "end_date" => nil
        )
      end
    end

    context "when the date is before the closed period starts" do
      let(:effective_on) { Date.new(2025, 12, 31) }

      it "is not a valid transition" do
        expect(transition).to be(false)
        expect(provider.errors[:base].join).to match(/cannot be within or before the period/)
      end

      it "leaves the periods untouched" do
        transition

        expect(periods).to contain_exactly(
          "start_date" => "2026-01-01",
          "end_date" => "2026-06-01"
        )
      end
    end

    context "when the date is the closed period's start date" do
      let(:effective_on) { Date.new(2026, 1, 1) }

      it "is not a valid transition" do
        expect(transition).to be(false)
        expect(provider.errors[:base].join).to match(/cannot be within or before the period/)
      end

      it "does not append a period that shadows the closed one" do
        transition

        expect(periods).to contain_exactly(
          "start_date" => "2026-01-01",
          "end_date" => "2026-06-01"
        )
      end
    end
  end

  context "when the effective date is before the provider existed" do
    let(:provider) do
      create(:provider, first_active_at: Date.new(2024, 5, 1), onboarded_at: Date.new(2024, 4, 1))
    end
    let(:effective_on) { Date.new(2019, 1, 1) }

    it "is not a valid transition" do
      expect(transition).to be(false)
      expect(provider.errors[:base].join).to match(/cannot be before the provider was onboarded/)
    end

    it "leaves the periods untouched" do
      transition

      expect(periods).to be_empty
    end
  end

  context "when the provider state changes before the lock is taken (stale snapshot)" do
    let(:provider) { create(:provider) }
    let(:effective_on) { Date.current }

    def open_periods
      periods.select { |period| period["end_date"].nil? }
    end

    def simulate_concurrent_apply
      applier = Provider.find(provider.id)

      applier.inactive_periods << { "start_date" => 1.month.ago.to_date.to_s, "end_date" => nil }
      applier.save!
    end

    it "short-circuits when the provider was already transitioned to the new status" do
      simulate_concurrent_apply

      result = described_class.call(provider: provider, new_status: "inactive",
                                    effective_on: effective_on, reasons: ["No current cohorts"])

      expect(result).to be(true)
      expect(open_periods.count).to eq(1)
    end

    it "refuses the transition when the concurrently created period conflicts with the date" do
      applier = Provider.find(provider.id)
      applier.inactive_periods << { "start_date" => (effective_on + 1.day).to_s, "end_date" => nil }
      applier.save!

      result = described_class.call(provider: provider, new_status: "offboarded",
                                    effective_on: effective_on, reasons: ["Financial viability"])

      expect(result).to be(false)
      expect(provider.errors[:base].join).to match(/cannot be within or before the period/)
      expect(open_periods).to contain_exactly(
        a_hash_including("start_date" => (effective_on + 1.day).to_s, "end_date" => nil)
      )
    end
  end
end
