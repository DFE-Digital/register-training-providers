RSpec.describe ProviderChange, type: :model do
  subject(:provider_change) { build(:provider_change) }

  describe "associations" do
    it { is_expected.to belong_to(:provider) }
    it { is_expected.to belong_to(:creator).class_name("User").with_foreign_key(:created_by_id).optional }
  end

  it { is_expected.to be_audited }

  describe "enums" do
    it do
      expect(described_class.statuses).to eq(
        "pending" => "pending",
        "completed" => "completed",
        "failed" => "failed"
      )
    end

    it do
      expect(described_class.sources).to eq(
        "requested" => "requested",
        "baseline" => "baseline"
      )
    end
  end

  describe "CHANGEABLE_ATTRIBUTES" do
    it "matches the attributes the provider changes registry offers wizards for" do
      expect(described_class::CHANGEABLE_ATTRIBUTES)
        .to match_array(ProviderChanges::Registry.fields)
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:attribute_name) }
    it { is_expected.to validate_presence_of(:value) }
    it { is_expected.to validate_presence_of(:effective_on) }

    it "only allows changeable provider attributes" do
      provider_change.attribute_name = "accreditation_status"

      expect(provider_change).not_to be_valid
      expect(provider_change.errors[:attribute_name]).to be_present
    end
    context "when the value is blank" do
      it "is invalid for a required attribute" do
        provider_change = build(:provider_change, attribute_name: "code", value: "")

        expect(provider_change).not_to be_valid
        expect(provider_change.errors[:value]).to include("can't be blank")
      end

      it "is valid for the optional legal name attribute" do
        provider_change = build(:provider_change, attribute_name: "legal_name", value: "")

        expect(provider_change).to be_valid
      end

      it "is valid for the optional urn attribute" do
        provider_change = build(:provider_change, attribute_name: "urn", value: "")

        expect(provider_change).to be_valid
      end

      it "normalises a nil urn to a blank string when stored" do
        provider_change = create(:provider_change, attribute_name: "urn", value: nil)

        expect(provider_change.reload.value).to eq("")
      end
    end
  end
  describe "baseline changes" do
    subject(:baseline) { create(:provider_change, :baseline) }

    it "is completed, so the nightly sweep can never re-apply it" do
      expect(baseline).to be_completed
    end

    it "is not restorable into a wizard as a pending change" do
      expect(baseline.provider.provider_changes.pending).to be_empty
    end

    it "is invisible to the pending value change lookup" do
      expect(
        described_class.pending_value_change(
          attribute: baseline.attribute_name,
          value: baseline.value,
          effective_on: baseline.effective_on
        )
      ).to be_empty
    end
  end

  describe "at most one baseline per attribute" do
    let(:provider) { create(:provider) }

    before { create(:provider_change, :baseline, provider:) }

    it "rejects a second baseline for the same attribute" do
      duplicate = build(:provider_change, :baseline, provider: provider, attribute_name: "code")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:attribute_name]).to include("has already been taken")
    end

    it "allows a second requested change for the same attribute" do
      expect(build(:provider_change, provider: provider, attribute_name: "code")).to be_valid
    end

    it "allows a baseline for another attribute" do
      expect(build(:provider_change, :baseline, provider: provider, attribute_name: "ukprn")).to be_valid
    end
  end

  describe ".for_attribute" do
    let!(:code_change) do
      create(:provider_change, attribute_name: "code")
    end

    let!(:ukprn_change) do
      create(:provider_change, :ukprn_change)
    end

    it "returns changes for the specified attribute" do
      expect(described_class.for_attribute("code")).to contain_exactly(code_change)
    end
  end

  describe ".effective_on_or_before" do
    let(:effective_on) { Date.new(2026, 9, 1) }

    let!(:before_change) do
      create(:provider_change, effective_on: effective_on - 1.day)
    end

    let!(:on_change) do
      create(:provider_change, effective_on:)
    end

    let!(:after_change) do
      create(:provider_change, effective_on: effective_on + 1.day)
    end

    it "returns changes effective on or before the specified date" do
      expect(described_class.effective_on_or_before(effective_on))
        .to contain_exactly(before_change, on_change)
    end
  end

  describe ".pending_value_change" do
    let(:effective_on) { Date.new(2026, 9, 1) }
    let(:value) { "ABC" }

    let!(:matching_change) do
      create(:provider_change, status: :pending, attribute_name: "code", value: value, effective_on: effective_on)
    end

    let!(:before_change) do
      create(:provider_change, status: :pending, attribute_name: "code", value: value, effective_on: effective_on - 1.day)
    end

    let!(:later_change) do
      create(:provider_change, status: :pending, attribute_name: "code", value: value, effective_on: effective_on + 1.day)
    end

    let!(:different_value_change) do
      create(:provider_change, status: :pending, attribute_name: "code", value: "XYZ", effective_on: effective_on)
    end

    let!(:different_attribute_change) do
      create(:provider_change, :ukprn_change, status: :pending, effective_on: effective_on)
    end

    let!(:completed_change) do
      create(
        :provider_change,
        status: :completed,
        attribute_name: "code",
        value: value,
        effective_on: effective_on
      )
    end

    it "returns pending changes for the attribute and value effective on or before the specified date" do
      expect(
        described_class.pending_value_change(attribute: "code", value: value, effective_on: effective_on)
      ).to contain_exactly(matching_change, before_change)
    end
  end

  describe ".history" do
    let!(:old_change) do
      create(
        :provider_change,
        effective_on: Date.new(2025, 1, 1),
        created_at: 2.days.ago
      )
    end

    let!(:newer_change) do
      create(
        :provider_change,
        effective_on: Date.new(2025, 2, 1),
        created_at: 1.day.ago
      )
    end

    let!(:same_date_later_created_change) do
      create(
        :provider_change,
        effective_on: Date.new(2025, 2, 1),
        created_at: Time.current
      )
    end

    it "orders by effective date descending, then creation date descending" do
      expect(described_class.history).to eq(
        [
          same_date_later_created_change,
          newer_change,
          old_change
        ]
      )
    end
  end
end
