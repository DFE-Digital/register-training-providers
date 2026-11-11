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
    it { is_expected.to have_many(:academic_years).through(:partnership_academic_years) }
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
      create(:partnership,
             accredited_provider: accredited_provider,
             provider: partner_zebra,
             duration: Date.new(2020, 1, 1)...Date.new(2021, 1, 1))
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

  describe "partnership types" do
    it "is valid with at least one partnership type" do
      expect(build(:partnership)).to be_valid
    end

    it "requires at least one partnership type" do
      partnership = build(:partnership, partnership_type: nil)

      expect(partnership).not_to be_valid
      expect(partnership.errors[:partnership_types]).to be_present
    end

    it "does not count a discarded type towards the requirement" do
      partnership = create(:partnership)
      partnership.partnership_types.sole.discard

      expect(partnership.reload).not_to be_valid
      expect(partnership.errors[:partnership_types]).to be_present
    end
  end

  describe "#status_label" do
    it "is Active once the partnership has started" do
      partnership.update!(duration: 1.day.ago..)

      expect(partnership.status_label).to eq("Active")
    end

    it "is Scheduled before the start date" do
      partnership.update!(duration: 1.month.from_now..)

      expect(partnership.status_label).to eq("Scheduled")
    end
  end

  describe "#sync_partnership_types" do
    it "discards removed types and builds added ones" do
      partnership.partnership_types.create!(partnership_type: PartnershipTypeEnum::TRAINING_AND_DELIVERY)

      partnership.sync_partnership_types(
        [PartnershipTypeEnum::TRAINING_AND_DELIVERY, PartnershipTypeEnum::STUDENT_FEE_MANAGEMENT]
      )
      partnership.save!

      expect(partnership.partnership_types.kept.map(&:partnership_type))
        .to match_array([PartnershipTypeEnum::TRAINING_AND_DELIVERY,
                         PartnershipTypeEnum::STUDENT_FEE_MANAGEMENT])
      expect(partnership.partnership_types.where(partnership_type: PartnershipTypeEnum::RECRUITMENT).sole)
        .to be_discarded
    end

    it "keeps unchanged types" do
      partnership.sync_partnership_types([PartnershipTypeEnum::RECRUITMENT])
      partnership.save!

      expect(partnership.partnership_types.kept.map(&:partnership_type))
        .to eq([PartnershipTypeEnum::RECRUITMENT])
    end
  end

  describe "#end!" do
    it "ends an open ended partnership today and keeps its start date" do
      starts_on = 1.year.ago.to_date
      partnership.update!(duration: starts_on..)

      expect(partnership.end!).to be(true)

      partnership.reload
      expect(partnership.duration.begin).to eq(starts_on)
      expect(partnership.duration.end).to eq(Time.zone.today)
      expect(described_class.ended).to include(partnership)
      expect(described_class.current_or_scheduled).not_to include(partnership)
    end

    it "shortens a partnership that has an end date in the future and keeps its start date" do
      starts_on = 1.year.ago.to_date
      partnership.update!(duration: starts_on...1.month.from_now)

      partnership.end!

      partnership.reload
      expect(partnership.duration.begin).to eq(starts_on)
      expect(partnership.duration.end).to eq(Time.zone.today)
    end

    it "refuses a partnership that has not started yet" do
      starts_on = 1.month.from_now.to_date
      partnership.update!(duration: starts_on..)

      expect(partnership.end!).to be(false)

      partnership.reload
      expect(partnership.duration.begin).to eq(starts_on)
      expect(partnership.duration.end).not_to be_a(Date)
    end

    it "refuses a partnership with no start date instead of raising" do
      partnership.update_columns(duration: nil...1.month.from_now)

      expect(partnership.end!).to be(false)
      expect(partnership.reload.duration.end).to eq(1.month.from_now.to_date)
    end

    it "refuses a partnership that starts today rather than writing an empty duration" do
      partnership.update!(duration: Time.zone.today..)

      expect(partnership.end!).to be(false)

      partnership.reload
      expect(partnership.duration.begin).to eq(Time.zone.today)
      expect(partnership.duration.end).not_to be_a(Date)
      expect(described_class.current_or_scheduled).to include(partnership)
      expect(partnership).not_to be_ended_on
    end

    it "frees its partnership types for a replacement partnership" do
      partnership.update!(duration: 1.year.ago..)
      pair = { accredited_provider_id: partnership.accredited_provider_id,
               provider_id: partnership.provider_id }

      expect(PartnershipType.used_between(**pair)).to be_present

      partnership.end!

      expect(PartnershipType.used_between(**pair)).to be_empty
    end

    it "refuses a partnership that has already ended" do
      partnership.update!(duration: 1.year.ago...1.month.ago)
      ends_on = partnership.duration.end.to_date

      expect(partnership.end!).to be(false)

      expect(partnership.reload.duration.end).to eq(ends_on)
    end
  end

  describe "#revise_types!" do
    let(:types) { [PartnershipTypeEnum::RECRUITMENT] }

    before { partnership.update!(duration: 1.year.ago..) }

    it "ends the current partnership today and starts a replacement with the new types" do
      replacement = partnership.revise_types!(
        types,
        academic_years: partnership.academic_years,
        end_date: nil
      )

      expect(replacement).to be_persisted
      expect(replacement.duration.begin).to eq(Time.zone.today)
      expect(replacement.partnership_types.kept.map(&:partnership_type)).to match_array(types)

      partnership.reload
      expect(partnership.duration.end).to eq(Time.zone.today)
      expect(described_class.ended).to include(partnership)
    end

    it "refuses a partnership that has not started yet instead of adding a second current partnership" do
      partnership.update!(duration: 1.month.from_now..)
      pair = { accredited_provider_id: partnership.accredited_provider_id,
               provider_id: partnership.provider_id }

      expect(partnership.revise_types!(types, academic_years: [], end_date: nil)).to be_nil
      expect(described_class.kept.current_or_scheduled.where(**pair).count).to eq(1)
    end

    it "refuses a partnership that started today, which is edited in place instead" do
      partnership.update!(duration: Time.zone.today..)

      expect(partnership.revise_types!(types,
                                       academic_years: partnership.academic_years,
                                       end_date: nil)).to be_nil
      expect(partnership.reload.duration.end).not_to be_a(Date)
    end

    it "refuses an end date that would leave the replacement with no days" do
      expect(partnership.revise_types!(types,
                                       academic_years: partnership.academic_years,
                                       end_date: 1.day.ago.to_date)).to be_nil

      expect(partnership.reload.duration.end).not_to be_a(Date)
    end

    it "leaves the original partnership alone when the replacement cannot be saved" do
      original = partnership

      allow_any_instance_of(Partnership).to receive(:save).and_wrap_original do |method, *args|
        method.receiver == original ? method.call(*args) : false
      end

      expect(original.revise_types!(types,
                                    academic_years: original.academic_years,
                                    end_date: nil)).to be_nil

      expect(original.duration.end).not_to be_a(Date)
      expect(original).not_to be_changed

      expect(original.reload.duration.end).not_to be_a(Date)
    end
  end

  describe "#same_day_replacement" do
    let(:types) { [PartnershipTypeEnum::TRAINING_AND_DELIVERY] }

    before { partnership.update!(duration: 1.year.ago..) }

    it "is the partnership created for the same pair today with the same types" do
      replacement = partnership.revise_types!(
        types,
        academic_years: partnership.academic_years,
        end_date: nil
      )

      expect(partnership.same_day_replacement(types)).to eq(replacement)
    end

    it "is nil when no replacement exists" do
      expect(partnership.same_day_replacement(types)).to be_nil
    end

    it "ignores another partnership for the pair created today with different types" do
      create(:partnership,
             accredited_provider: partnership.accredited_provider,
             provider: partnership.provider,
             duration: Time.zone.today..,
             partnership_type: PartnershipTypeEnum::TRAINING_AND_DELIVERY)

      expect(partnership.same_day_replacement([PartnershipTypeEnum::RECRUITMENT,
                                               PartnershipTypeEnum::TRAINING_AND_DELIVERY]))
        .to be_nil
    end
  end

  describe "#can_be_ended?" do
    it "is true once the partnership has started and has not ended" do
      partnership.update!(duration: 1.year.ago...)

      expect(partnership).to be_can_be_ended
    end

    it "is false on the start date, when there is no day before today to end it on" do
      partnership.update!(duration: Time.zone.today..)

      expect(partnership).not_to be_can_be_ended
    end

    it "is false when the partnership has only a start date in the future" do
      partnership.update!(duration: 1.month.from_now..)

      expect(partnership).not_to be_can_be_ended
    end

    it "is false when the partnership has already ended" do
      partnership.update!(duration: 1.year.ago...1.month.ago)

      expect(partnership).not_to be_can_be_ended
    end

    it "is false when the partnership has no dates" do
      undated = build(:partnership, duration: nil)

      expect(undated).not_to be_can_be_ended
    end
  end

  describe ".ended" do
    let(:accredited_provider) { create(:provider, :accredited) }

    let!(:ended_partnership) do
      create(:partnership, accredited_provider: accredited_provider, duration: Date.new(2020, 1, 1)...Date.new(2021, 1, 1))
    end
    let!(:open_ended_partnership) do
      create(:partnership, accredited_provider: accredited_provider, duration: Date.new(2020, 1, 1)..)
    end

    it "includes partnerships that have ended" do
      expect(described_class.ended).to include(ended_partnership)
    end

    it "excludes open ended partnerships" do
      expect(described_class.ended).not_to include(open_ended_partnership)
    end

    it "puts a partnership ending today in exactly one list" do
      boundary = create(:partnership,
                        accredited_provider: accredited_provider,
                        duration: Date.new(2020, 1, 1)...Time.zone.today)

      expect(described_class.ended).to include(boundary)
      expect(described_class.current_or_scheduled).not_to include(boundary)
    end
  end

  describe ".current_or_scheduled" do
    let(:accredited_provider) { create(:provider, :accredited) }

    let!(:open_ended) do
      create(:partnership, accredited_provider: accredited_provider, duration: Date.new(2020, 1, 1)..)
    end
    let!(:ends_in_the_future) do
      create(:partnership,
             accredited_provider: accredited_provider,
             duration: Date.new(2020, 1, 1)...(Time.zone.today + 1.year))
    end
    let!(:ended) do
      create(:partnership,
             accredited_provider: accredited_provider,
             duration: Date.new(2020, 1, 1)...Date.new(2021, 1, 1))
    end

    it "includes open ended and not yet ended partnerships" do
      expect(described_class.current_or_scheduled).to include(open_ended, ends_in_the_future)
    end

    it "excludes ended partnerships" do
      expect(described_class.current_or_scheduled).not_to include(ended)
    end
  end
end
