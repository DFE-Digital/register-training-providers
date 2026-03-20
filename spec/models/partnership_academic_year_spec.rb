require "rails_helper"

RSpec.describe PartnershipAcademicYear, type: :model do
  let(:partnership_academic_year) { create(:partnership_academic_year) }

  it { is_expected.to be_audited }
  it { is_expected.to be_kept }

  context "partnership_academic_year is discarded" do
    before do
      partnership_academic_year.discard!
    end

    it "the partnership_academic_year is discarded" do
      expect(partnership_academic_year).to be_discarded
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:partnership) }
    it { is_expected.to belong_to(:academic_year) }
  end
end
