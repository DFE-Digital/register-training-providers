require "rails_helper"

RSpec.describe Partnerships::Steps::EndDateStep do
  subject(:step) { described_class.new(end_date_day:, end_date_month:, end_date_year:) }

  let(:end_date_day) { 31 }
  let(:end_date_month) { 7 }
  let(:end_date_year) { 2026 }

  it "builds the end date" do
    expect(step).to be_valid
    expect(step.end_date).to eq(Date.new(2026, 7, 31))
  end

  context "when no date is given" do
    let(:end_date_day) { nil }
    let(:end_date_month) { nil }
    let(:end_date_year) { nil }

    it "is invalid" do
      expect(step).not_to be_valid
      expect(step.errors[:end_date]).to include("Enter date the partnership ended")
    end
  end

  context "when the date cannot exist" do
    let(:end_date_day) { 31 }
    let(:end_date_month) { 2 }

    it "says so" do
      expect(step).not_to be_valid
      expect(step.errors[:end_date].join).to include("must be a real date")
    end
  end

  context "when the end date is before the start date" do
    subject(:step) { described_class.new(end_date_day:, end_date_month:, end_date_year:, wizard:) }

    let(:repository) { DfE::Wizard::Repository::InMemory.new }
    let(:state_store) { Partnerships::StateStores::PartnershipStore.new(repository:) }
    let(:wizard) { double(state_store:) }

    before { state_store.write(start_date: Date.new(2026, 9, 1)) }

    it "rejects it" do
      expect(step).not_to be_valid
      expect(step.errors[:end_date].join).to include("must be after")
    end
  end
end
