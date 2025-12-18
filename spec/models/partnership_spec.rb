require "rails_helper"

RSpec.describe Partnership, type: :model do
  let(:partnership) { create(:partnership) }

  it { is_expected.to be_audited }
  it { is_expected.to be_kept }

  context "partnership is discarded" do
    before do
      partnership.discard!
    end

    it "the user is discarded" do
      expect(partnership).to be_discarded
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:provider) }
    it { is_expected.to belong_to(:accredited_provider) }
    it { is_expected.to have_many(:academic_cycles).through(:partnership_academic_cycles) }
  end

  describe "#other_partner" do
    context "when it is the training partner" do
      it "is expected to return the accredited provider" do
        expect(partnership.other_partner(partnership.provider)).to eq(partnership.accredited_provider)
      end
    end

    context "when it is the accredited provider" do
      it "is expected to return the accredited provider" do
        expect(partnership.other_partner(partnership.accredited_provider)).to eq(partnership.provider)
      end
    end
  end
end
