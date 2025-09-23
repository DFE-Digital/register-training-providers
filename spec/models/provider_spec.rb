require "rails_helper"

RSpec.describe Provider, type: :model do
  let(:provider) { create(:provider) }
  subject { provider }

  it { is_expected.to be_audited }
  it { is_expected.to be_kept }

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

    it { is_expected.to allow_value("ABC").for(:code) }
    it { is_expected.to allow_value("a1B").for(:code) }
    it { is_expected.not_to allow_value("abcdx").for(:code).with_message("Enter a valid provider code") }

    context "when provider_type is school or scitt" do
      [:school, :scitt].each do |provider_type|
        let(:provider) { build(:provider, provider_type, urn:) }

        context "urn is set to nil" do
          let(:urn) { nil }
          it "requires URN" do
            expect(subject.valid?).to be_falsey
            expect(subject.errors[:urn]).to include("Enter unique reference number (URN)")
          end
        end

        context "urn is set to an invalid value" do
          let(:urn) { "invalid" }
          it "requires valid URN" do
            expect(subject.valid?).to be_falsey
            expect(subject.errors[:urn]).to include("Enter a valid unique reference number (URN)")
          end
        end
      end
    end

    context "when provider_type is hei" do
      let(:provider) { build(:provider, :hei, urn: nil) }

      it "does not require URN" do
        expect(subject.valid?).to be_truthy
        expect(subject.errors[:urn]).to be_empty
      end
    end
  end

  describe "upcase_code callback" do
    let(:provider) { build(:provider, code: "abc") }

    it "upcases the code before saving" do
      expect(provider.code).to eq("abc")

      provider.save!

      expect(provider.code).to eq("ABC")
    end
  end

  describe "#sync_accreditation_status!" do
    context "when provider type switching is needed" do
      context "when school becomes accredited" do
        let(:provider) { create(:provider, :school) }

        it "changes provider type to scitt and status to accredited when accreditation is added" do
          # Initially unaccredited school
          expect(provider.provider_type).to eq("school")
          expect(provider.accreditation_status).to eq("unaccredited")

          # Add a current accreditation - this should trigger automatic sync via callback
          create(:accreditation, :current, provider: provider, number: "5123")

          # Check that the provider was automatically switched
          provider.reload
          expect(provider.provider_type).to eq("scitt")
          expect(provider.accreditation_status).to eq("accredited")
        end
      end

      context "when scitt loses accreditation" do
        let(:provider) { create(:provider, :accredited, :scitt) }

        it "changes provider type to school and status to unaccredited when accreditation expires" do
          # Initially accredited scitt (factory creates accreditation)
          expect(provider.provider_type).to eq("scitt")
          expect(provider.accreditation_status).to eq("accredited")

          # Make the accreditation expire
          provider.accreditations.update_all(end_date: 1.day.ago)

          # Manually trigger sync to test the logic
          provider.sync_accreditation_status!

          # Check that provider switched to school
          expect(provider.reload.provider_type).to eq("school")
          expect(provider.reload.accreditation_status).to eq("unaccredited")
        end
      end

      context "when non-school provider becomes accredited" do
        let(:provider) { create(:provider, :hei) }

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

  describe "#archive!" do
    it "sets archived_at" do
      expect { provider.archive! }.to change { provider.archived_at }.from(nil).to(
        be_within(1.second).of(Time.zone.now.utc)
      )
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
    let(:provider) { build(:provider, :archived) }
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
end
