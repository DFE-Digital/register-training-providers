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

  describe "#code=" do
    let(:provider) { build(:provider, code: "abc") }

    it "upcases the code" do
      expect(subject.code).to eq("ABC")
    end
  end

  describe "#school_accreditation_status" do
    let(:provider) { build(:provider, provider_type:, accreditation_status:) }

    before { subject.validate }

    context "when provider is a school and accredited" do
      let(:provider_type) { :school }
      let(:accreditation_status) { :accredited }

      it "adds error to provider_type" do
        expect(subject.errors[:provider_type]).to include("School cannot be accredited")
      end

      it "adds error to accreditation_status" do
        expect(subject.errors[:accreditation_status]).to include("School cannot be accredited")
      end
    end

    context "when provider is a school and unaccredited" do
      let(:provider_type) { :school }
      let(:accreditation_status) { :unaccredited }

      it "does not add errors" do
        expect(subject.errors.messages).to be_empty
      end
    end
  end

  describe ".order_by_operating_name" do
    let!(:p1) { create(:provider, operating_name: "Zed") }
    let!(:p2) { create(:provider, operating_name: "Alpha") }

    it "returns providers ordered by operating_name" do
      expect(described_class.order_by_operating_name).to eq([p2, p1])
    end
  end
end
