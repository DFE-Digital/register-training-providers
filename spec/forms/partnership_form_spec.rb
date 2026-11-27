require "rails_helper"

RSpec.describe PartnershipForm, type: :model do
  let(:provider) { create(:provider) }
  let(:accredited_provider) { create(:provider, :accredited) }
  let(:academic_year) { create(:academic_year) }
  let(:valid_attributes) do
    {
      provider_id: provider.id,
      accredited_provider_id: accredited_provider.id,
      academic_year_ids: [academic_year.id],
      start_date_day: 1,
      start_date_month: 9,
      start_date_year: Date.current.year
    }
  end

  describe "validations" do
    it "requires start_date with custom message" do
      form = described_class.new(valid_attributes.merge(
                                   start_date_day: nil,
                                   start_date_month: nil,
                                   start_date_year: nil
                                 ))

      expect(form).not_to be_valid
      expect(form.errors[:start_date]).to include("Enter date the partnership started")
    end

    it "requires at least one academic_year_id" do
      form = described_class.new(valid_attributes.merge(academic_year_ids: []))

      expect(form).not_to be_valid
      expect(form.errors[:academic_year_ids]).to be_present
    end

    it "rejects an academic year outside the eligible window" do
      form = described_class.new(valid_attributes.merge(eligible_academic_year_ids: []))

      expect(form).not_to be_valid
      expect(form.errors[:academic_year_ids])
        .to include("Select an academic year available for these partnership dates")
    end

    it "accepts an eligible academic year" do
      form = described_class.new(valid_attributes.merge(eligible_academic_year_ids: [academic_year.id.to_s]))

      expect(form).to be_valid
    end

    context "when the save will revise the partnership" do
      let(:revision_attributes) { valid_attributes.merge(revision_on: Time.zone.today) }

      it "rejects an end date that is not after the day the replacement starts" do
        form = described_class.new(revision_attributes.merge(
                                     end_date_day: Time.zone.today.day,
                                     end_date_month: Time.zone.today.month,
                                     end_date_year: Time.zone.today.year
                                   ))

        expect(form).not_to be_valid
        expect(form.errors[:end_date])
          .to include("End date must be after #{Time.zone.today.to_fs(:govuk)}")
      end

      it "rejects a start date that leaves no day to end the current record on" do
        form = described_class.new(revision_attributes.merge(
                                     start_date_day: Time.zone.today.day,
                                     start_date_month: Time.zone.today.month,
                                     start_date_year: Time.zone.today.year
                                   ))

        expect(form).not_to be_valid
        expect(form.errors[:start_date])
          .to include("Start date must be before #{Time.zone.today.to_fs(:govuk)}, " \
                      "when the partnership types are also changing")
      end

      it "accepts dates that bracket today" do
        form = described_class.new(revision_attributes.merge(
                                     start_date_day: 1,
                                     start_date_month: 9,
                                     start_date_year: Time.zone.today.year - 1,
                                     end_date_day: 31,
                                     end_date_month: 7,
                                     end_date_year: Time.zone.today.year + 1
                                   ))

        expect(form).to be_valid
      end
    end
  end

  describe "#to_partnership_attributes" do
    it "returns attributes for creating partnership" do
      form = described_class.new(valid_attributes)
      attributes = form.to_partnership_attributes

      expect(attributes[:provider]).to eq(provider)
      expect(attributes[:accredited_provider]).to eq(accredited_provider)
      expect(attributes[:academic_years]).to include(academic_year)
      expect(attributes[:duration]).to be_a(Range)
    end
  end
end
