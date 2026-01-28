require "rails_helper"

RSpec.describe XlsxRowImporter::PartnershipService do
  subject(:call_importer) { described_class.call(row) }

  let!(:accredited_provider) { create(:provider, code: "1CS") }
  let!(:provider)            { create(:provider, code: "2CJ") }

  let(:row) do
    {
      "partnership__accredited_provider_provider_code" => "1CS",
      "partnership__training_partner_provider_code" => "2CJ",
      "partnership__start_date" => Date.new(2024, 8, 1),
      "partnership__end_date" => nil,
      "partnership__academic_years_active" => "2024, 2025, 2026"
    }
  end

  before do
    [2024, 2025, 2026].each do |year|
      create(:academic_cycle, academic_year: year)
    end
  end

  describe ".call" do
    it "creates a partnership between the two providers" do
      expect { call_importer }
        .to change(Partnership, :count).by(1)

      partnership = Partnership.last
      expect(partnership.accredited_provider).to eq(accredited_provider)
      expect(partnership.provider).to eq(provider)
    end

    it "creates academic cycles and links them to the partnership" do
      call_importer

      years = Partnership.last.academic_cycles.map do |cycle|
        cycle.duration.begin.year
      end

      expect(years).to match_array([2024, 2025, 2026])
    end

    it "does not create duplicate academic cycles on re-import" do
      call_importer

      expect { call_importer }
        .not_to change(PartnershipAcademicCycle, :count)
    end

    it "does not create a duplicate partnership on re-import" do
      call_importer

      expect { call_importer }
        .not_to change(Partnership, :count)
    end

    it "appends partnership seed data to both providers" do
      call_importer

      [accredited_provider.reload, provider.reload].each do |p|
        imports = p.seed_data_notes["partnership_imports"]

        expect(imports.size).to eq(1)
        expect(imports.first["saved_as"]["partnership_id"]).to be_present
      end
    end

    context "when the same provider appears in multiple partnerships" do
      let!(:other_provider) { create(:provider, code: "2CG") }

      let(:second_row) do
        row.merge(
          "partnerships__provider_id_lookup_by_code" => "2CG"
        )
      end

      it "appends without overwriting" do
        described_class.call(row)
        described_class.call(second_row)

        imports = accredited_provider.reload
                                     .seed_data_notes["partnership_imports"]

        provider_codes = imports.map do |entry|
          entry["row_imported"]["provider_code"]
        end

        expect(provider_codes).to match_array(%w[2CJ 2CG])
      end
    end

    context "when a provider has multiple accredited providers" do
      let!(:second_accredited_provider) { create(:provider, code: "3AB") }

      let(:second_row) do
        row.merge(
          "partnerships__accredited_provider_id_lookup_by_code" => "3AB"
        )
      end

      it "records both partnerships" do
        described_class.call(row)
        described_class.call(second_row)

        imports = provider.reload
                          .seed_data_notes["partnership_imports"]

        accredited_codes = imports.map do |entry|
          entry["row_imported"]["accredited_provider_code"]
        end

        expect(accredited_codes).to match_array(%w[1CS 3AB])
      end
    end
  end
end
