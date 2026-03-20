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
