require "rails_helper"

RSpec.describe PartnershipType, type: :model do
  it { is_expected.to be_audited }

  describe "associations" do
    it { is_expected.to belong_to(:partnership) }
  end

  describe "validations" do
    it "is valid with the default attributes" do
      expect(build(:partnership_type)).to be_valid
    end

    it "requires a partnership type" do
      partnership_type = build(:partnership_type, partnership_type_value: nil)

      expect(partnership_type).not_to be_valid
      expect(partnership_type.errors[:partnership_type]).to be_present
    end

    it "does not allow the same type twice on one partnership" do
      partnership = create(:partnership, partnership_type: PartnershipTypeEnum::RECRUITMENT)
      duplicate = partnership.partnership_types.build(partnership_type: PartnershipTypeEnum::RECRUITMENT)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:partnership_type]).to be_present
    end

    context "when the partner pair already has a current partnership with the type" do
      let(:accredited_provider) { create(:provider, :accredited) }
      let(:partner) { create(:provider, :school) }

      let!(:existing_partnership) do
        create(:partnership,
               accredited_provider: accredited_provider,
               provider: partner,
               partnership_type: PartnershipTypeEnum::RECRUITMENT)
      end

      it "rejects the same type on another current partnership with the same partner" do
        other = build(:partnership,
                      accredited_provider: accredited_provider,
                      provider: partner,
                      partnership_type: PartnershipTypeEnum::TRAINING_AND_DELIVERY)
        other.partnership_types.build(partnership_type: PartnershipTypeEnum::RECRUITMENT)

        expect(other).not_to be_valid
        expect(other.partnership_types.last.errors[:partnership_type]).to be_present
      end

      it "allows a different type on another current partnership with the same partner" do
        other = build(:partnership,
                      accredited_provider: accredited_provider,
                      provider: partner,
                      partnership_type: PartnershipTypeEnum::TRAINING_AND_DELIVERY)

        expect(other).to be_valid
      end

      it "allows the type once the existing partnership has ended" do
        existing_partnership.update!(duration: Date.new(2020, 1, 1)...Date.new(2021, 1, 1))

        other = build(:partnership,
                      accredited_provider: accredited_provider,
                      provider: partner,
                      partnership_type: PartnershipTypeEnum::RECRUITMENT)

        expect(other).to be_valid
      end

      it "allows a historical partnership to reuse a type held by a current one" do
        historical = build(:partnership,
                           accredited_provider: accredited_provider,
                           provider: partner,
                           duration: Date.new(2020, 1, 1)...Date.new(2021, 1, 1),
                           partnership_type: PartnershipTypeEnum::RECRUITMENT)

        expect(historical).to be_valid
      end

      it "allows the type against a different partner" do
        other = build(:partnership,
                      accredited_provider: accredited_provider,
                      provider: create(:provider, :school),
                      partnership_type: PartnershipTypeEnum::RECRUITMENT)

        expect(other).to be_valid
      end

      it "allows the type once the earlier type was discarded" do
        existing_partnership.partnership_types.sole.discard

        other = build(:partnership,
                      accredited_provider: accredited_provider,
                      provider: partner,
                      partnership_type: PartnershipTypeEnum::RECRUITMENT)

        expect(other).to be_valid
      end
    end

    context "when a partnership's dates move it back into the current window" do
      let(:accredited_provider) { create(:provider, :accredited) }
      let(:partner) { create(:provider, :school) }

      let!(:ended_partnership) do
        create(:partnership,
               accredited_provider: accredited_provider,
               provider: partner,
               duration: Date.new(2020, 1, 1)...Date.new(2021, 1, 1))
      end
      let!(:current_partnership) do
        create(:partnership,
               accredited_provider: accredited_provider,
               provider: partner,
               duration: Date.new(2023, 1, 1)..)
      end

      it "rejects the reopen while the type is used by a current partnership" do
        ended_partnership.duration = (Date.new(2020, 1, 1)..)

        expect(ended_partnership).not_to be_valid
        expect(ended_partnership.errors[:base]).to be_present
      end

      it "allows the reopen once the other partnership has ended" do
        current_partnership.update!(duration: Date.new(2023, 1, 1)...Date.new(2024, 1, 1))
        ended_partnership.duration = (Date.new(2020, 1, 1)..)

        expect(ended_partnership).to be_valid
      end
    end

    context "when the partnership type is placement" do
      it "is valid with a school partner" do
        partnership = build(:partnership, :placement, provider: create(:provider, :school))

        expect(partnership).to be_valid
      end

      it "is invalid when the training partner is not a school" do
        partnership = build(:partnership,
                            provider: create(:provider, :hei_without_accreditation),
                            partnership_type: PartnershipTypeEnum::PLACEMENT)

        expect(partnership).not_to be_valid
        expect(partnership.partnership_types.last.errors[:partnership_type]).to be_present
      end
    end
  end

  describe "#partnership_type_label" do
    it "returns the label used in the design" do
      partnership_type = build(:partnership_type,
                               partnership_type_value: PartnershipTypeEnum::STUDENT_FEE_MANAGEMENT)

      expect(partnership_type.partnership_type_label).to eq("Student Fee Management")
    end
  end

  describe "discarding" do
    it "keeps the record but removes it from kept" do
      partnership_type = create(:partnership_type)

      partnership_type.discard

      expect(partnership_type).to be_discarded
      expect(described_class.exists?(partnership_type.id)).to be(true)
      expect(described_class.kept).not_to include(partnership_type)
    end

    it "is not hard deleted when the partnership is discarded" do
      partnership = create(:partnership)
      partnership_type = partnership.partnership_types.sole

      partnership.discard

      expect(described_class.exists?(partnership_type.id)).to be(true)
      expect(partnership_type.reload).not_to be_discarded
    end
  end
end
