RSpec.describe ProviderChanges::Steps::StatusEffectiveDateStep do
  subject(:step) { described_class.new(**step_attributes, wizard: wizard, step_id: :effective_date) }

  let(:wizard) { instance_double(ProviderChanges::StatusWizard, provider:) }
  let(:provider) { create(:provider) }
  let(:step_attributes) do
    { effective_on_day: effective_on.day,
      effective_on_month: effective_on.month,
      effective_on_year: effective_on.year }
  end
  let(:effective_on) { Date.new(2027, 1, 15) }

  describe "validations" do
    it "is valid" do
      expect(step).to be_valid
    end

    context "when the date is missing" do
      let(:step_attributes) { {} }

      it "is not valid" do
        step.valid?

        expect(step.errors[:effective_on])
          .to include("Enter date that the status change applies from")
      end
    end

    context "when the date is malformed" do
      let(:step_attributes) { { effective_on_day: nil, effective_on_month: 1, effective_on_year: "" } }

      it "is not valid" do
        step.valid?

        expect(step.errors[:effective_on])
          .to include("Date that the status change applies from must include a day and year must include 4 numbers")
      end
    end

    context "when the provider has an open period" do
      let(:provider) do
        create(:provider).tap do |provider|
          provider.inactive_periods << { "start_date" => "2027-01-15", "end_date" => nil }
          provider.save!
        end
      end

      context "when the date is before the open period starts" do
        let(:effective_on) { Date.new(2027, 1, 14) }

        it "is not valid" do
          step.valid?

          expect(step.errors[:effective_on])
            .to include("Enter a date that is not within or before an existing period")
        end
      end

      context "when the date is the day the open period started" do
        it "is valid" do
          expect(step).to be_valid
        end
      end
    end

    context "when the date is before the provider existed" do
      let(:provider) { create(:provider, first_active_at: Date.new(2024, 5, 1), onboarded_at: Date.new(2024, 4, 1)) }
      let(:effective_on) { Date.new(2019, 1, 1) }

      it "is not valid" do
        step.valid?

        expect(step.errors[:effective_on])
          .to include("Enter a date that is not before the provider was onboarded")
      end
    end

    context "when the date is before the provider existed and before a closed period" do
      let(:provider) do
        create(:provider,
               first_active_at: Date.new(2024, 5, 1),
               onboarded_at: Date.new(2024, 4, 1)).tap do |provider|
          provider.inactive_periods << { "start_date" => "2025-01-01", "end_date" => "2025-06-01" }
          provider.save!
        end
      end
      let(:effective_on) { Date.new(2019, 1, 1) }

      it "reports the onboarding reason, not the period reason" do
        step.valid?

        expect(step.errors[:effective_on])
          .to include("Enter a date that is not before the provider was onboarded")
        expect(step.errors[:effective_on])
          .not_to include("Enter a date that is not within or before an existing period")
      end
    end

    context "when the provider has a closed period" do
      let(:provider) do
        create(:provider).tap do |provider|
          provider.inactive_periods << { "start_date" => "2027-01-01", "end_date" => "2027-03-01" }
          provider.save!
        end
      end

      context "when the date falls inside the closed period" do
        let(:effective_on) { Date.new(2027, 2, 15) }

        it "is not valid" do
          step.valid?

          expect(step.errors[:effective_on])
            .to include("Enter a date that is not within or before an existing period")
        end
      end

      context "when the date is the day the closed period started" do
        let(:effective_on) { Date.new(2027, 1, 1) }

        it "is not valid" do
          step.valid?

          expect(step.errors[:effective_on])
            .to include("Enter a date that is not within or before an existing period")
        end
      end

      context "when the date is the day before the closed period started" do
        let(:effective_on) { Date.new(2026, 12, 31) }

        it "is not valid" do
          step.valid?

          expect(step.errors[:effective_on])
            .to include("Enter a date that is not within or before an existing period")
        end
      end

      context "when the date is after the closed period" do
        let(:effective_on) { Date.new(2027, 3, 2) }

        it "is valid" do
          expect(step).to be_valid
        end
      end
    end
  end
end
