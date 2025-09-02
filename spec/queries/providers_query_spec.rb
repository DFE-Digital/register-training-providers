require "rails_helper"

RSpec.describe ProvidersQuery do
  subject(:results) { described_class.call(filters:, search_term:) }
  let(:search_term) { nil }

  describe "#call (filters only)" do
    let!(:scitt)                { create(:provider, :scitt, :accredited) }
    let!(:school)               { create(:provider, :school, :unaccredited) }
    let!(:accredited_hei)       { create(:provider, :hei, :accredited) }
    let!(:unaccredited_hei)     { create(:provider, :hei, :unaccredited) }
    let!(:accredited_other)     { create(:provider, :other, :accredited) }
    let!(:unaccredited_other)   { create(:provider, :other, :unaccredited) }
    let!(:archived_accredited_hei) do
      create(:provider, :hei, :accredited, archived_at: 1.week.ago)
    end

    context "without filters" do
      let(:filters) { {} }

      it "returns all non-archived providers" do
        expect(results).to match_array([
          scitt,
          school,
          accredited_hei,
          unaccredited_hei,
          accredited_other,
          unaccredited_other
        ])
      end
    end

    context "with show_archived_provider" do
      let(:filters) { { show_archived: "show_archived_provider" } }

      it "includes archived providers" do
        expect(results).to include(archived_accredited_hei, scitt, school)
      end
    end

    describe "provider_types filtering" do
      [
        { types: ["scitt_or_school"], expected: -> { [scitt, school] } },
        { types: ["hei"], expected: -> { [accredited_hei, unaccredited_hei] } },
        { types: ["other"], expected: -> { [accredited_other, unaccredited_other] } },
        { types: ["hei", "other"], expected: -> { [accredited_hei, unaccredited_hei, accredited_other, unaccredited_other] } },
        { types: ["hei", "other", "scitt_or_school"], expected: -> { [scitt, school, accredited_hei, unaccredited_hei, accredited_other, unaccredited_other] } }
      ].each do |case_data|
        context "when provider_types is #{case_data[:types].inspect}" do
          let(:filters) { { provider_types: case_data[:types] } }

          it "returns only matching providers" do
            expect(results).to match_array(instance_exec(&case_data[:expected]))
          end
        end
      end
    end

    context "accreditation_statuses filtering" do
      let(:filters) { { accreditation_statuses: ["accredited"] } }

      it "returns all accredited non-archived providers" do
        expect(results).to match_array([scitt, accredited_hei, accredited_other])
      end
    end

    describe "combined provider_types and accreditation_statuses filters" do
      context "scitt_or_school + accredited" do
        let(:filters) { { provider_types: ["scitt_or_school"], accreditation_statuses: ["accredited"] } }
        it { is_expected.to match_array([scitt]) }
      end

      context "scitt_or_school + unaccredited" do
        let(:filters) { { provider_types: ["scitt_or_school"], accreditation_statuses: ["unaccredited"] } }
        it { is_expected.to match_array([school]) }
      end

      context "scitt_or_school + both statuses" do
        let(:filters) { { provider_types: ["scitt_or_school"], accreditation_statuses: ["accredited", "unaccredited"] } }
        it { is_expected.to match_array([scitt, school]) }
      end

      context "hei + accredited" do
        let(:filters) { { provider_types: ["hei"], accreditation_statuses: ["accredited"] } }
        it { is_expected.to match_array([accredited_hei]) }
      end
    end

    context "when all filter values are unknown" do
      let(:filters) { { provider_types: ["foobar"], accreditation_statuses: ["gibberish"] } }

      it "returns an empty result set" do
        expect(results).to be_empty
      end
    end
  end

  describe "#call (search term)" do
    let!(:matching_provider) { create(:provider, operating_name: "Bright Future Academy", urn: "123456", ukprn: "78901234") }
    let!(:other_provider)    { create(:provider, operating_name: "Sunshine School", urn: "654321", ukprn: "43210987") }

    context "when search term matches operating_name" do
      it "returns matching providers" do
        results = described_class.call(search_term: "Bright Future")
        expect(results).to contain_exactly(matching_provider)
      end
    end

    context "when search term matches part of operating_name" do
      it "returns matching providers" do
        results = described_class.call(search_term: "Bright")
        expect(results).to contain_exactly(matching_provider)
      end
    end

    context "when search term matches urn" do
      it "returns matching providers" do
        results = described_class.call(search_term: "123456")
        expect(results).to contain_exactly(matching_provider)
      end
    end

    context "when search term matches ukprn" do
      it "returns matching providers" do
        results = described_class.call(search_term: "78901234")
        expect(results).to contain_exactly(matching_provider)
      end
    end

    context "when search term does not match anything" do
      it "returns an empty result" do
        results = described_class.call(search_term: "Nonexistent")

        expect(results).to be_empty
      end
    end

    context "when search term is nil" do
      it "returns all providers" do
        results = described_class.call(search_term: nil)
        expect(results).to match_array([matching_provider, other_provider])
      end
    end
  end

  context "with filters and a search term" do
    let!(:scitt_accredited) { create(:provider, :scitt, accreditation_status: :accredited, operating_name: "Alpha Teaching Trust") }
    let!(:school_unaccredited) { create(:provider, :school, accreditation_status: :unaccredited, operating_name: "Alpha Academy") }

    let(:filters) { { provider_types: ["scitt_or_school"], accreditation_statuses: ["accredited"] } }
    let(:search_term) { "Alpha" }

    it "returns only providers matching both filters and search term" do
      expect(results).to contain_exactly(scitt_accredited)
    end
  end
end
