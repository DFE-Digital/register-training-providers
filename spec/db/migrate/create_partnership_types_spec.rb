require "rails_helper"
require Rails.root.join("db/migrate/20261109120000_create_partnership_types")

RSpec.describe CreatePartnershipTypes do
  subject(:backfill) { described_class.new.backfill_recruitment_type }

  it "gives every kept and discarded partnership a single recruitment type" do
    current = create(:partnership)
    ended = create(:partnership, duration: Date.new(2020, 1, 1)...Date.new(2021, 1, 1))
    discarded = create(:partnership)
    discarded.discard

    PartnershipType.delete_all

    backfill

    expect(PartnershipType.pluck(:partnership_id)).to match_array([current.id, ended.id, discarded.id])
    expect(PartnershipType.distinct.pluck(:partnership_type)).to eq([PartnershipTypeEnum::RECRUITMENT])
    expect(PartnershipType.distinct.pluck(:source)).to eq(["backfill"])
  end

  it "is idempotent" do
    create(:partnership)

    PartnershipType.delete_all

    backfill
    backfill

    expect(PartnershipType.count).to eq(1)
  end
end
