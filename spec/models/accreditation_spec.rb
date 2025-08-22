require "rails_helper"

RSpec.describe Accreditation, type: :model do
  let(:accreditation) { create(:accreditation) }
  subject { accreditation }

  it_behaves_like "uuid identifiable"

  it { is_expected.to be_audited }

  describe "associations" do
    it { is_expected.to belong_to(:provider) }
  end

  describe "validations" do
    it "is valid with valid attributes" do
      accreditation = build(:accreditation)
      expect(accreditation).to be_valid
    end

    it "requires a number" do
      accreditation = build(:accreditation, number: nil)
      expect(accreditation).not_to be_valid
      expect(accreditation.errors[:number]).to include("can't be blank")
    end

    it "requires a start_date" do
      accreditation = build(:accreditation, start_date: nil)
      expect(accreditation).not_to be_valid
      expect(accreditation.errors[:start_date]).to include("can't be blank")
    end
  end

  describe "scopes" do
    let(:provider) { create(:provider, :unaccredited) }
    let!(:current_accreditation) { create(:accreditation, :current, provider:) }
    let!(:expired_accreditation) { create(:accreditation, :expired, provider:) }
    let!(:future_accreditation) { create(:accreditation, :future, provider:) }

    describe ".current" do
      it "returns only current accreditations" do
        expect(Accreditation.current).to contain_exactly(current_accreditation)
      end

      it "includes accreditations with no end date that have started" do
        indefinite_accreditation = create(:accreditation, :indefinite, provider:)
        expect(Accreditation.current).to include(indefinite_accreditation)
      end
    end

    describe ".order_by_start_date" do
      it "orders accreditations by start date" do
        accreditations = Accreditation.order_by_start_date
        expect(accreditations.first).to eq(expired_accreditation)
        expect(accreditations.last).to eq(future_accreditation)
      end
    end
  end
end
