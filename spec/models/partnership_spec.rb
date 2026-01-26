require "rails_helper"

RSpec.describe Partnership, type: :model do
  let(:partnership) { create(:partnership) }

  it { is_expected.to be_audited }
  it { is_expected.to be_kept }

  context "partnership is discarded" do
    before do
      partnership.discard!
    end

    it "the partnership is discarded" do
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

  describe ".ordered_by_partner_and_date" do
    let(:accredited_provider) { create(:provider, :accredited, operating_name: "Accredited Provider") }
    let(:partner_zebra) { create(:provider, :hei, :unaccredited, operating_name: "Zebra University") }
    let(:partner_alpha) { create(:provider, :hei, :unaccredited, operating_name: "Alpha College") }
    let(:partner_123) { create(:provider, :hei, :unaccredited, operating_name: "123 Academy") }

    let!(:partnership_zebra_old) do
      create(:partnership, accredited_provider: accredited_provider, provider: partner_zebra, duration: Date.new(2020, 1, 1)..)
    end
    let!(:partnership_alpha) do
      create(:partnership, accredited_provider: accredited_provider, provider: partner_alpha, duration: Date.new(2022, 1, 1)..)
    end
    let!(:partnership_123) do
      create(:partnership, accredited_provider: accredited_provider, provider: partner_123, duration: Date.new(2021, 1, 1)..)
    end
    let!(:partnership_zebra_new) do
      create(:partnership, accredited_provider: accredited_provider, provider: partner_zebra, duration: Date.new(2023, 1, 1)..)
    end

    it "orders by partner name (0-9, a-z), then by start date (oldest first)" do
      ordered = accredited_provider.partnerships.ordered_by_partner_and_date(accredited_provider)

      expect(ordered.to_a).to eq([
        partnership_123,
        partnership_alpha,
        partnership_zebra_old,
        partnership_zebra_new
      ])
    end

    context "when viewing from unaccredited provider perspective" do
      let(:training_provider) { create(:provider, :hei, :unaccredited, operating_name: "Training Provider") }
      let(:accredited_alpha) { create(:provider, :accredited, operating_name: "Alpha Accredited") }
      let(:accredited_zebra) { create(:provider, :accredited, operating_name: "Zebra Accredited") }

      let!(:partnership_with_alpha) do
        create(:partnership, provider: training_provider, accredited_provider: accredited_alpha, duration: Date.new(2022, 1, 1)..)
      end
      let!(:partnership_with_zebra) do
        create(:partnership, provider: training_provider, accredited_provider: accredited_zebra, duration: Date.new(2021, 1, 1)..)
      end

      it "orders by accredited provider name when viewing as training provider" do
        ordered = training_provider.partnerships.ordered_by_partner_and_date(training_provider)

        expect(ordered.to_a).to eq([partnership_with_alpha, partnership_with_zebra])
      end
    end
  end
end
