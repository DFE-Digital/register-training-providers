require "rails_helper"

RSpec.describe Provider, type: :model do
  describe "Provider status" do
    subject(:provider) { create(:provider) }

    it "is active by default" do
      expect(provider.status).to eq("active")
    end

    it "labels the current status" do
      expect(provider.status_label).to eq("Active")
    end

    it "allows the documented status transitions" do
      expect(provider.allowed_status_transitions).to eq(%i[inactive offboarded])
      expect(provider).to be_transitionable_status("inactive")
      expect(provider).to be_transitionable_status("offboarded")
    end

    context "when the provider is inactive" do
      let(:provider) { create(:provider, :with_current_inactive_period) }

      it "is inactive" do
        expect(provider.status).to eq("inactive")
        expect(provider.status_label).to eq("Inactive")
        expect(provider.allowed_status_transitions).to eq(%i[active offboarded])

        expect(provider.open_offboarded_period).to be_nil
      end

      it "stores the period's reasons under the same key production writes" do
        expect(provider.current_inactive_period["reasons_for_inactive"]).to eq(["None given"])
      end
    end

    context "when the provider is offboarded" do
      let(:provider) { create(:provider, :with_current_offboarded_period) }

      it "is offboarded" do
        expect(provider.status).to eq("offboarded")
        expect(provider.status_label).to eq("Offboarded")
        expect(provider.allowed_status_transitions).to eq(%i[active inactive])

        expect(provider.open_offboarded_period).to be_present
      end
    end

    context "when the provider is archived" do
      let(:provider) { create(:provider, :archived) }

      it "is archived" do
        expect(provider.status).to eq("archived")
        expect(provider.status_label).to eq("Archived")
      end
    end

    describe "offboarded periods" do
      let(:provider) do
        create(:provider).tap do |provider|
          provider.inactive_periods << {
            "start_date" => Date.new(2025, 1, 1),
            "end_date" => Date.new(2025, 6, 1),
            "offboarded" => true
          }
          provider.inactive_periods << {
            "start_date" => Date.new(2025, 8, 1),
            "end_date" => Date.new(2025, 12, 1),
            "offboarded" => true
          }
          provider.save!
        end
      end

      it "falls back to the latest completed offboarded period" do
        expect(provider.offboarded_period["start_date"]).to eq("2025-08-01")
      end

      it "keeps the provider active once the offboarded period has ended" do
        expect(provider.status).to eq("active")
      end
    end
  end

  describe "ProviderStatusEnum.earliest_valid_date" do
    subject(:provider) { build_stubbed(:provider, first_active_at:, onboarded_at:) }

    context "when only onboarded_at is present" do
      let(:first_active_at) { nil }
      let(:onboarded_at) { Date.new(2025, 3, 1) }

      it { expect(ProviderStatusEnum.earliest_valid_date(provider)).to eq(Date.new(2025, 3, 1)) }
    end

    context "when only first_active_at is present" do
      let(:first_active_at) { Date.new(2025, 4, 1) }
      let(:onboarded_at) { nil }

      it { expect(ProviderStatusEnum.earliest_valid_date(provider)).to eq(Date.new(2025, 4, 1)) }
    end

    context "when both are present" do
      let(:first_active_at) { Date.new(2025, 2, 15) }
      let(:onboarded_at) { Date.new(2025, 3, 1) }

      it "picks the earlier of the two" do
        expect(ProviderStatusEnum.earliest_valid_date(provider)).to eq(Date.new(2025, 2, 15))
      end
    end

    context "when neither is present" do
      let(:first_active_at) { nil }
      let(:onboarded_at) { nil }

      it { expect(ProviderStatusEnum.earliest_valid_date(provider)).to be_nil }
    end
  end

  describe "ProviderStatusEnum.period_conflicting_with_date" do
    it "returns nil when the date misses every period" do
      closed_period = [{ "start_date" => "2025-01-01", "end_date" => "2025-06-01" }]

      expect(ProviderStatusEnum.period_conflicting_with_date([], Date.new(2025, 1, 1))).to be_nil
      expect(ProviderStatusEnum.period_conflicting_with_date(closed_period, Date.new(2025, 7, 1))).to be_nil
    end

    it "conflicts with a date inside a closed period" do
      periods = [{ "start_date" => "2025-01-01", "end_date" => "2025-06-01" }]

      expect(ProviderStatusEnum.period_conflicting_with_date(periods, Date.new(2025, 3, 1))).to eq(periods.sole)
    end

    it "conflicts with a date equal to a closed period's start date" do
      periods = [{ "start_date" => "2025-01-01", "end_date" => "2025-06-01" }]

      expect(ProviderStatusEnum.period_conflicting_with_date(periods, Date.new(2025, 1, 1))).to eq(periods.sole)
    end

    it "conflicts with a date equal to a closed period's end date" do
      periods = [{ "start_date" => "2025-01-01", "end_date" => "2025-06-01" }]

      expect(ProviderStatusEnum.period_conflicting_with_date(periods, Date.new(2025, 6, 1))).to eq(periods.sole)
    end

    it "conflicts with a date before a closed period starts" do
      periods = [{ "start_date" => "2025-01-01", "end_date" => "2025-06-01" }]

      expect(ProviderStatusEnum.period_conflicting_with_date(periods, Date.new(2024, 12, 31))).to eq(periods.sole)
    end

    it "conflicts with a date before an open period starts" do
      periods = [{ "start_date" => "2025-01-01", "end_date" => nil }]

      expect(ProviderStatusEnum.period_conflicting_with_date(periods, Date.new(2024, 12, 31))).to eq(periods.sole)
    end

    it "does not conflict with the date an open period started" do
      periods = [{ "start_date" => "2025-01-01", "end_date" => nil }]

      expect(ProviderStatusEnum.period_conflicting_with_date(periods, Date.new(2025, 1, 1))).to be_nil
    end

    it "returns the period a date conflicts with, even alongside non-conflicting ones" do
      open_period = { "start_date" => "2026-01-01", "end_date" => nil }
      closed_period = { "start_date" => "2027-01-01", "end_date" => "2027-06-01" }

      expect(
        ProviderStatusEnum.period_conflicting_with_date([open_period, closed_period], Date.new(2027, 3, 1))
      ).to eq(closed_period)
    end
  end
end
