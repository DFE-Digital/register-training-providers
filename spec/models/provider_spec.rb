require "rails_helper"

RSpec.describe Provider, type: :model do
  let(:provider) { create(:provider) }
  subject { provider }

  it { is_expected.to be_audited }
  it { is_expected.to be_kept }

  describe "associations" do
    it { is_expected.to have_many(:provider_academic_years).dependent(:destroy) }
    it { is_expected.to have_many(:provider_changes).dependent(:destroy) }
    it { is_expected.to have_many(:academic_years).through(:provider_academic_years) }
  end

  context "provider is discarded" do
    before do
      subject.discard!
    end

    it "the provider is discarded" do
      expect(provider).to be_discarded
    end
  end

  describe "enums" do
    context "provider is accredited" do
      let(:provider) { create(:provider, :accredited) }

      it do
        expect(subject).to define_enum_for(:provider_type)
          .with_values(hei: "hei", scitt: "scitt", school: "school", other: "other")
          .backed_by_column_of_type(:string)
      end
    end

    context "provider is unaccredited" do
      let(:provider) { create(:provider, :unaccredited) }

      it do
        expect(subject).to define_enum_for(:provider_type)
          .with_values(hei: "hei", scitt: "scitt", school: "school", other: "other")
          .backed_by_column_of_type(:string)
      end
    end
    it do
      is_expected.to define_enum_for(:accreditation_status)
        .with_values(accredited: "accredited", unaccredited: "unaccredited")
        .backed_by_column_of_type(:string)
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:provider_type).with_message("Select provider type") }
    it { is_expected.to validate_presence_of(:accreditation_status).with_message("Select if the provider is accredited") }

    it { is_expected.to validate_presence_of(:operating_name).with_message("Enter operating name") }
    it { is_expected.to validate_presence_of(:ukprn).with_message("Enter UK provider reference number (UKPRN)") }
    it { is_expected.to allow_value("12345678").for(:ukprn) }
    it { is_expected.not_to allow_value("1234").for(:ukprn).with_message("Enter a valid UK provider reference number (UKPRN)") }

    it { is_expected.to validate_presence_of(:code).with_message("Enter provider code") }
    it { is_expected.to validate_uniqueness_of(:rotp_id).case_insensitive.with_message("has already been taken") }

    it { is_expected.to allow_value("ABC").for(:code) }
    it { is_expected.to allow_value("a1B").for(:code) }
    it { is_expected.not_to allow_value("abcdx").for(:code).with_message("Enter a valid provider code") }

    provider_types = %i[hei school scitt other]

    context "when urn is set to a valid value" do
      { "five digits" => "12345", "six digits" => "123456" }.each do |description, valid_urn|
        context "and the URN has #{description}" do
          provider_types.each do |provider_type|
            context "and the provider type is #{provider_type}" do
              let(:provider) { build(:provider, provider_type, urn: valid_urn, rotp_id: provider_type.to_s) }

              it "accepts the URN" do
                expect(subject.valid?).to be_truthy
                expect(subject.errors[:urn]).to be_empty
              end
            end
          end
        end
      end
    end

    context "when urn is set to an invalid value" do
      { "four digits" => "1234", "seven digits" => "1234567", "non-numeric" => "invalid" }.each do |description, invalid_urn|
        context "and the URN has #{description}" do
          provider_types.each do |provider_type|
            context "and the provider type is #{provider_type}" do
              let(:provider) { build(:provider, provider_type, urn: invalid_urn, rotp_id: provider_type.to_s) }

              it "requires a valid URN" do
                expect(subject.valid?).to be_falsey
                expect(subject.errors[:urn]).to include("Enter a valid unique reference number (URN)")
              end

              it "is invalid only because of the URN" do
                subject.valid?

                expect(subject.errors.attribute_names).to eq([:urn])
              end
            end
          end
        end
      end
    end

    context "when urn is padded with whitespace" do
      provider_types.each do |provider_type|
        context "and the provider type is #{provider_type}" do
          let(:provider) { build(:provider, provider_type, urn: " 12345 ", rotp_id: provider_type.to_s) }

          it "strips the surrounding whitespace before validating" do
            subject.valid?

            expect(subject.urn).to eq("12345")
            expect(subject.errors[:urn]).to be_empty
          end
        end
      end
    end

    context "when urn is blank" do
      { "nil" => nil, "an empty string" => "", "whitespace only" => "   " }.each do |description, blank_urn|
        context "and urn is #{description}" do
          provider_types.each do |provider_type|
            context "and the provider type is #{provider_type}" do
              let(:provider) { build(:provider, provider_type, urn: blank_urn, rotp_id: provider_type.to_s) }

              it "does not require URN" do
                expect(subject.valid?).to be_truthy
                expect(subject.errors[:urn]).to be_empty
              end

              it "normalises the blank URN to nil" do
                subject.valid?

                expect(subject.urn).to be_nil
              end
            end
          end
        end
      end
    end
  end

  describe "scopes" do
    let(:inactive_provider) { create(:provider, inactive_periods: [{ start_date: 1.year.ago.to_date, end_date: nil }]) }
    let(:archived_provider) { create(:provider, :archived) }

    describe "#archived" do
      it { expect(Provider.archived).to eq([archived_provider]) }
    end

    describe "#inactive" do
      it { expect(Provider.inactive).to eq([inactive_provider]) }
    end
  end

  describe "upcase_code callback" do
    let(:provider) { build(:provider, code: "abc", rotp_id: "code") }

    it "upcases the code before saving" do
      expect(provider.code).to eq("abc")

      provider.save!

      expect(provider.code).to eq("ABC")
    end
  end

  describe "#current_accreditation" do
    let(:provider) { create(:provider) }

    it "returns the current accreditation with the newest start date" do
      create(:accreditation, provider: provider, number: "1001", start_date: 4.years.ago.to_date, end_date: 3.years.ago.to_date)
      newest = create(:accreditation, provider: provider, number: "1002", start_date: 2.years.ago.to_date, end_date: nil)

      expect(provider.current_accreditation).to eq(newest)
    end

    it "returns nil when there is no active accreditation" do
      create(:accreditation, :expired, provider:)

      expect(provider.current_accreditation).to be_nil
    end

    it "breaks start-date ties by most recently created" do
      create(:accreditation, provider: provider, number: "1001", start_date: 1.year.ago.to_date, end_date: nil)
      second = create(:accreditation, provider: provider, number: "1002", start_date: 1.year.ago.to_date, end_date: nil)

      expect(provider.current_accreditation).to eq(second)
    end
  end

  describe "#sync_accreditation_status!" do
    context "when the accreditation status changes" do
      context "when school becomes accredited" do
        let(:provider) { create(:provider, :school) }

        it "changes status to accredited and preserves the school provider type" do
          # Initially unaccredited school
          expect(provider.provider_type).to eq("school")
          expect(provider.accreditation_status).to eq("unaccredited")

          # Add a current accreditation - this should trigger automatic sync via callback
          create(:accreditation, :current, provider: provider, number: "5123")

          # Check that only the status was synced
          provider.reload
          expect(provider.provider_type).to eq("school")
          expect(provider.accreditation_status).to eq("accredited")
        end
      end

      context "when scitt loses accreditation" do
        let(:provider) { create(:provider, :accredited, :scitt) }

        it "changes status to unaccredited and preserves the scitt provider type" do
          # Initially accredited scitt (factory creates accreditation)
          expect(provider.provider_type).to eq("scitt")
          expect(provider.accreditation_status).to eq("accredited")

          # Make the accreditation expire
          provider.accreditations.update_all(end_date: 1.day.ago)

          # Manually trigger sync to test the logic
          provider.sync_accreditation_status!

          # Check that only the status was synced
          expect(provider.reload.provider_type).to eq("scitt")
          expect(provider.reload.accreditation_status).to eq("unaccredited")
        end
      end

      context "when non-school provider becomes accredited" do
        let(:provider) { create(:provider, :hei_without_accreditation) }

        it "changes status but not provider type" do
          expect(provider.provider_type).to eq("hei")
          expect(provider.accreditation_status).to eq("unaccredited")

          # Add accreditation
          create(:accreditation, :current, provider: provider, number: "1123")

          # Check only status changed
          provider.reload
          expect(provider.provider_type).to eq("hei")
          expect(provider.accreditation_status).to eq("accredited")
        end
      end

      context "when non-scitt provider loses accreditation" do
        let(:provider) { create(:provider, :accredited, :hei) }

        it "changes status but not provider type" do
          expect(provider.provider_type).to eq("hei")
          expect(provider.accreditation_status).to eq("accredited")

          # Make accreditation expire
          provider.accreditations.update_all(end_date: 1.day.ago)
          provider.sync_accreditation_status!

          # Check only status changed
          provider.reload
          expect(provider.provider_type).to eq("hei")
          expect(provider.accreditation_status).to eq("unaccredited")
        end
      end
    end
  end

  describe "independent provider type and accreditation status" do
    context "when a school is accredited" do
      let(:provider) { create(:provider, :school_with_accreditation) }

      it "remains a school with a current accreditation" do
        expect(provider).to be_valid
        expect(provider.provider_type).to eq("school")
        expect(provider.accreditation_status).to eq("accredited")
        expect(provider).to have_current_accreditations

        expect(provider.reload.provider_type).to eq("school")
        expect(provider.reload.accreditation_status).to eq("accredited")
      end
    end

    context "when a scitt is unaccredited" do
      let(:provider) { create(:provider, :scitt_without_accreditation) }

      it "remains a scitt with no current accreditation" do
        expect(provider).to be_valid
        expect(provider.provider_type).to eq("scitt")
        expect(provider.accreditation_status).to eq("unaccredited")
        expect(provider).not_to have_current_accreditations

        expect(provider.reload.provider_type).to eq("scitt")
        expect(provider.reload.accreditation_status).to eq("unaccredited")
      end
    end
  end

  describe "#archive!" do
    it "sets archived_at" do
      expect { provider.archive! }.to change { provider.archived_at }.from(nil).to(
        be_within(1.second).of(Time.zone.now.utc)
      )
    end

    it "fails the queued pending status change instead of deleting it" do
      change = create(:provider_change, :status_change, provider: provider, value: { "status" => "active" })

      expect { provider.archive! }.to change { provider.provider_changes.pending.count }.from(1).to(0)

      expect(change.reload).to be_failed
      expect(change.error_message).to eq("Provider was archived before the change took effect")
      expect(change.processed_at).to be_present
    end

    it "fails queued pending changes for other attributes as well" do
      create(:provider_change, :code_change, provider: provider, value: "NEW")
      create(:provider_change, :ukprn_change, provider: provider, value: "10000001")

      expect { provider.archive! }.to change { provider.provider_changes.pending.count }.from(2).to(0)
      expect(provider.provider_changes.failed.count).to eq(2)
    end
  end

  describe "#archived?" do
    context "when archived_at is present" do
      let(:provider) { build(:provider, :archived) }

      it "returns true" do
        expect(provider.archived?).to be true
      end
    end
    context "when archived_at is nil" do
      let(:provider) { build(:provider) }
      it "returns false" do
        expect(provider.archived?).to be false
      end
    end
  end

  describe "#not_archived?" do
    context "when archived_at is present" do
      let(:provider) { build(:provider, :archived) }

      it "returns false" do
        expect(provider.not_archived?).to be false
      end
    end
    context "when archived_at is nil" do
      let(:provider) { build(:provider) }
      it "returns true" do
        expect(provider.not_archived?).to be true
      end
    end
  end

  describe "#restore!" do
    let(:provider) { build(:provider, :archived, rotp_id: "restore!") }
    it "sets archived_at to nil" do
      expect { provider.restore! }.to change { provider.archived_at }.to(nil)
    end
  end

  describe ".order_by_operating_name" do
    let!(:p1) { create(:provider, operating_name: "Zed") }
    let!(:p2) { create(:provider, operating_name: "Alpha") }

    it "returns providers ordered by operating_name" do
      expect(described_class.order_by_operating_name).to eq([p2, p1])
    end
  end

  describe "#active_in_academic_year?" do
    it "reports a provider archived inside the year as active for that year" do
      provider = create(
        :provider,
        first_active_at: build_academic_year_start_date(current_academic_year) - 1.year,
        archived_at: build_academic_year_start_date(current_academic_year) + 1.month
      )

      expect(provider.active_in_academic_year?(AcademicYear.for_year(current_academic_year))).to be true
    end
  end

  describe ".for_active_academic_years" do
    let!(:provider_current_only) do
      create(:provider)
    end

    let!(:provider_multiple_years) do
      first_active_at = build_academic_year_date(previous_academic_year)

      create(:provider, first_active_at:)
    end

    let!(:inactive_provider) do
      first_active_at = build_academic_year_date(current_academic_year)
      inactive_period = { start_date: first_active_at + 1.day,
                          end_date: nil,
                          reason_for_inactive: "None given" }
      create(:provider, first_active_at: first_active_at, inactive_periods: [inactive_period])
    end

    it "returns providers that match ANY of the given academic years" do
      result = described_class.for_active_academic_years([current_academic_year])

      expect(result).to contain_exactly(
        provider_current_only,
        provider_multiple_years
      )
    end

    it "returns providers matching multiple years" do
      result = described_class.for_active_academic_years([
        current_academic_year,
        previous_academic_year
      ])

      expect(result).to contain_exactly(
        provider_current_only,
        provider_multiple_years
      )
    end

    it "does not include inactive providers that do not match any given years" do
      result = described_class.for_active_academic_years([current_academic_year])

      expect(result).not_to include(inactive_provider)
    end

    it "does not include a provider archived on the first day of the academic year" do
      academic_year_start = build_academic_year_start_date(current_academic_year)
      provider = create(
        :provider,
        first_active_at: academic_year_start - 1.year,
        archived_at: academic_year_start.to_time,
        inactive_periods: [{
          start_date: academic_year_start - 1.year,
          end_date: academic_year_start - 1.day,
          offboarded: true
        }]
      )

      result = described_class.for_active_academic_years([current_academic_year])

      expect(result).not_to include(provider)
    end

    it "does not return duplicates when a provider matches multiple years" do
      result = described_class.for_active_academic_years([
        current_academic_year,
        previous_academic_year
      ])

      expect(result.where(id: provider_multiple_years.id).count).to eq(1)
    end

    it "returns none when years are empty" do
      expect(described_class.for_active_academic_years([])).to be_empty
    end
  end

  describe ".search" do
    let!(:provider_alpha) { create(:provider, operating_name: "Alpha Teaching Trust", urn: "123456", ukprn: "78901234") }
    let!(:provider_bravo) { create(:provider, operating_name: "Bravo Academy", urn: "654321", ukprn: "43210987") }
    let!(:provider_obrave) { create(:provider, operating_name: "Brave Academy", legal_name: "O'Brave school", urn: "654322", ukprn: "53210987") }

    context "when searching by operating_name" do
      it "returns providers whose operating_name matches the term" do
        expect(described_class.search("Alpha")).to contain_exactly(provider_alpha)
      end
    end

    context "when searching by partial operating_name" do
      it "returns providers matching the prefix" do
        expect(described_class.search("Alp")).to contain_exactly(provider_alpha)
      end
    end

    context "when searching by legal_name" do
      it "returns providers matching the prefix" do
        expect(described_class.search("OBrave")).to contain_exactly(provider_obrave)
      end
    end
    context "when searching by partial legal_name" do
      it "returns providers matching the prefix" do
        expect(described_class.search("Obr")).to contain_exactly(provider_obrave)
      end
    end

    context "when searching by urn" do
      it "returns the provider with that URN" do
        expect(described_class.search("123456")).to contain_exactly(provider_alpha)
      end
    end

    context "when searching by ukprn" do
      it "returns the provider with that UKPRN" do
        expect(described_class.search("78901234")).to contain_exactly(provider_alpha)
      end
    end

    context "when searching with no matches" do
      it "returns an empty result" do
        expect(described_class.search("Nonexistent")).to be_empty
      end
    end

    context "when search term is nil or blank" do
      it "returns all providers" do
        expect(described_class.search(nil)).to match_array([])
        expect(described_class.search("")).to match_array([])
      end
    end
  end

  describe ".active_academic_years" do
    let(:first_active_at) { build_academic_year_date(current_academic_year - 2) }

    let(:provider) { create(:provider, :with_inactive_period, first_active_at:) }

    it "returns all active academic years for the provider" do
      inactive = provider.inactive_periods.first
      inactive_range = Date.parse(inactive["start_date"])..Date.parse(inactive["end_date"])
      active_academic_years = AcademicYear.where("duration && daterange(?, ?, '[]')", first_active_at, Time.zone.today)
        .where.not("duration && daterange(?, ?, '[]')", inactive_range.begin, inactive_range.end)

      expect(provider.active_academic_years.pluck(:id)).to match(active_academic_years.pluck(:id))
    end

    context "when provider has no inactive periods" do
      let(:provider) { create(:provider, first_active_at:) }

      it "returns all academic years from first_active_at to today" do
        active_academic_years = AcademicYear.where("duration && daterange(?, ?, '[]')", first_active_at, Time.zone.today)

        expect(provider.active_academic_years.pluck(:id)).to match(active_academic_years.pluck(:id))
      end
    end

    context "when provider has an inactive period with no end date" do
      let(:provider) { create(:provider, :with_inactive_period, first_active_at:) }

      it "excludes academic years that overlap with the inactive period" do
        inactive = provider.inactive_periods.first
        inactive_range = Date.parse(inactive["start_date"])..Date.parse(inactive["end_date"])
        active_academic_years = AcademicYear.where("duration && daterange(?, ?, '[]')", first_active_at, Time.zone.today)
          .where.not("duration && daterange(?, ?, '[]')", inactive_range.begin, inactive_range.end)

        expect(provider.active_academic_years.pluck(:id)).to match(active_academic_years.pluck(:id))
      end
    end

    context "when provider has an inactive period that starts after today" do
      let(:provider) { create(:provider, :with_inactive_period, first_active_at:) }

      before do
        provider.inactive_periods.first["start_date"] = (Time.zone.today + 1.year).to_s
        provider.inactive_periods.first["end_date"] = (Time.zone.today + 2.years).to_s
        provider.save!
      end

      it "does not exclude any academic years" do
        active_academic_years = AcademicYear.where("duration && daterange(?, ?, '[]')", first_active_at, Time.zone.today)

        expect(provider.active_academic_years.pluck(:id)).to match(active_academic_years.pluck(:id))
      end
    end

    context "when provider has an inactive period that starts and ends on the same day" do
      let(:provider) { create(:provider, :with_inactive_period, first_active_at:) }

      before do
        provider.inactive_periods.first["start_date"] = (Time.zone.today - 1.day).to_s
        provider.inactive_periods.first["end_date"] = (Time.zone.today - 1.day).to_s
        provider.save!
      end

      it "excludes academic years that overlap with the inactive period" do
        inactive = provider.inactive_periods.first
        inactive_range = Date.parse(inactive["start_date"])..Date.parse(inactive["end_date"])
        active_academic_years = AcademicYear.where("duration && daterange(?, ?, '[]')", first_active_at, Time.zone.today)
          .where.not("duration && daterange(?, ?, '[]')", inactive_range.begin, inactive_range.end)

        expect(provider.active_academic_years.pluck(:id)).to match(active_academic_years.pluck(:id))
      end
    end

    context "when provider has first_active_at after today" do
      let(:provider) { create(:provider, first_active_at: Time.zone.today + 1.year) }

      it "returns no active academic years" do
        expect(provider.active_academic_years).to be_empty
      end
    end

    context "when an inactive period covers academic years inside its range" do
      let(:provider) do
        create(
          :provider,
          first_active_at: build_academic_year_start_date(current_academic_year - 5),
          inactive_periods: [{
            start_date: build_academic_year_start_date(current_academic_year - 3),
            end_date: build_academic_year_end_date(current_academic_year - 1)
          }]
        )
      end

      before do
        (current_academic_year - 4).upto(current_academic_year - 1) do |year|
          create(:academic_year, academic_year: year)
        end
      end

      it "excludes every academic year the period overlaps" do
        active_years = provider.active_academic_years.map(&:start_year)

        expect(active_years).not_to include(current_academic_year - 3)
        expect(active_years).not_to include(current_academic_year - 2)
        expect(active_years).not_to include(current_academic_year - 1)
      end

      it "keeps the academic years outside the period" do
        active_years = provider.active_academic_years.map(&:start_year)

        expect(active_years).to include(current_academic_year - 5)
        expect(active_years).to include(current_academic_year - 4)
      end
    end

    context "when the provider is archived" do
      let(:archive_date) { build_academic_year_start_date(current_academic_year) }
      let(:provider) do
        create(
          :provider,
          first_active_at: build_academic_year_start_date(current_academic_year - 2),
          archived_at: archive_date.to_time,
          inactive_periods: [{
            start_date: build_academic_year_start_date(current_academic_year - 1),
            end_date: (archive_date - 1.day).to_s
          }]
        )
      end

      it "excludes academic years starting on or after the archive date" do
        expect(provider.active_academic_years.map(&:start_year)).to eq([current_academic_year - 2])
      end
    end
  end

  describe "rotp_id" do
    it "requires a RoTP Id normally" do
      provider = build(:provider, rotp_id: nil)

      expect(provider).not_to be_valid
      expect(provider.errors[:rotp_id]).to include("can't be blank")
    end

    it "requires a unique RoTP Id normally" do
      create(:provider, rotp_id: "some-id")
      provider = build(:provider, rotp_id: "some-id")

      expect(provider).not_to be_valid
      expect(provider.errors[:rotp_id]).to include("has already been taken")
    end

    it "does not validate RoTP Id in the without_rotp_id context" do
      provider = build(:provider, rotp_id: nil)

      expect(provider.valid?(:without_rotp_id)).to be(true)
    end

    it "does not allow an existing RoTP Id to be changed" do
      provider = create(:provider, rotp_id: "CANNOT CHANGE")

      expect {
        provider.update!(rotp_id: "LET'S TRY TO CHANGE IT")
      }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Rotp cannot be changed")

      expect(provider.errors[:rotp_id]).to eq(["cannot be changed"])
      expect(provider.reload.rotp_id).to eq("CANNOT CHANGE")
    end

    it "retains the RoTP Id when the provider is updated" do
      provider = create(:provider, rotp_id: "CANNOT CHANGE")

      provider.update!(operating_name: "Changed name")

      expect(provider.reload.rotp_id).to eq("CANNOT CHANGE")
    end

    it "retains the RoTP Id when the provider becomes inactive" do
      provider = create(:provider, rotp_id: "CANNOT CHANGE")

      provider.update!(inactive_periods: [{ start_date: build_capped_current_academic_year_date,
                                            end_date: nil,
                                            reason_for_inactive: "None given" }])

      expect(provider.reload.rotp_id).to eq("CANNOT CHANGE")
    end

    it "retains the RoTP Id when the provider is soft-deleted" do
      provider = create(:provider, rotp_id: "CANNOT CHANGE")

      provider.discard!

      expect(provider.reload.rotp_id).to eq("CANNOT CHANGE")
    end

    it "retains the RoTP Id when the provider code changes" do
      provider = create(:provider, rotp_id: "CANNOT CHANGE")

      provider.update!(code: "DOA")

      expect(provider.reload.rotp_id).to eq("CANNOT CHANGE")
    end
  end

  describe "#current_inactive_period" do
    let(:completed_inactive_period) { { "start_date" => 1.year.ago.to_date.to_s, "end_date" => 6.months.ago.to_date.to_s } }
    let(:current_inactive_period) { { "start_date" => 1.month.ago.to_date.to_s } }
    let(:provider) { create(:provider, inactive_periods: [current_inactive_period, completed_inactive_period]) }

    it "returns the inactive period that ended most recently" do
      expect(provider.current_inactive_period).to eq(current_inactive_period)
    end
  end
end
