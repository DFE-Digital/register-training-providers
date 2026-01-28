# spec/services/provider_xlsx_row_importer_spec.rb
require "rails_helper"

RSpec.describe XlsxRowImporter::ProviderService do
  subject(:call_importer) { described_class.call(row) }

  let(:base_row) do
    {
      "provider__code" => "W1P",
      "provider__legal_name" => "Legal Name Ltd",
      "provider__operating_name" => "Operating Name",
      "provider__provider_type" => "hei",
      "provider__accreditation_status" => "accredited",
      "provider__ukprn" => "12345678",
      "provider__urn" => "876543",

      "accreditation__number" => "1001",
      "accreditation__start_date" => "2024-01-01",
      "accreditation__end_date" => "2026-01-01",

      "address__postcode" => "SW1A 1AA",
      "address__address_line_1" => "10 Downing Street",
      "address__town_or_city" => "London",
      "address__county" => "Greater London",
      "address__uprn" => "100023336956",
      "address__latitude" => "51.5033635",
      "address__longitude" => "-0.1276248",

      "found" => "true"
    }
  end

  let(:row) { base_row }

  describe ".call" do
    it "instantiates and calls the service" do
      importer = instance_double(described_class)

      expect(described_class).to receive(:new).with(row).and_return(importer)
      expect(importer).to receive(:call)

      described_class.call(row)
    end
  end

  describe "#call" do
    context "when the provider does not exist" do
      it "creates a provider, accreditation and address" do
        expect { call_importer }
          .to change(Provider, :count).by(1)
          .and change(Accreditation, :count).by(1)
          .and change(Address, :count).by(1)

        provider = Provider.last
        accreditation = provider.accreditations.first
        address = provider.addresses.first

        expect(provider).to have_attributes(
          code: "W1P",
          legal_name: "Legal Name Ltd",
          operating_name: "Operating Name",
          provider_type: "hei",
          ukprn: "12345678",
          urn: "876543"
        )

        expect(accreditation).to have_attributes(
          number: "1001",
          start_date: Date.parse("2024-01-01"),
          end_date: Date.parse("2026-01-01")
        )

        expect(address).to have_attributes(
          postcode: "SW1A 1AA",
          town_or_city: "London",
          county: "Greater London",
          uprn: "100023336956",
          latitude: 51.503364,
          longitude: -0.127625
        )
      end
    end

    describe "provider_type mapping" do
      context "when provider_type is scitt and accreditation_status is unaccredited" do
        let(:row) do
          base_row.merge(
            "provider__provider_type" => "scitt",
            "provider__accreditation_status" => "unaccredited"
          )
        end

        it "persists provider_type as school" do
          call_importer
          expect(Provider.last.provider_type).to eq("school")
        end
      end

      context "when provider_type is scitt but accreditation_status is accredited" do
        let(:row) do
          base_row.merge(
            "provider__provider_type" => "scitt",
            "provider__accreditation_status" => "accredited",
            "accreditation__number" => "5001",
          )
        end

        it "keeps provider_type as scitt" do
          call_importer
          expect(Provider.last.provider_type).to eq("scitt")
        end
      end

      context "when provider_type is not scitt" do
        let(:row) do
          base_row.merge(
            "provider__provider_type" => "hei",
            "provider__accreditation_status" => "unaccredited"
          )
        end

        it "keeps provider_type unchanged" do
          call_importer
          expect(Provider.last.provider_type).to eq("hei")
        end
      end
    end

    context "when the provider already exists" do
      let!(:provider) { create(:provider, code: "W1P", legal_name: "Old Name") }

      it "updates the provider in place" do
        expect { call_importer }.not_to change(Provider, :count)

        provider.reload
        expect(provider.legal_name).to eq("Legal Name Ltd")
        expect(provider.operating_name).to eq("Operating Name")
      end
    end

    context "when UKPRN is missing" do
      before { row["provider__ukprn"] = nil }

      it "uses the default UKPRN and records a seed data error" do
        call_importer
        provider = Provider.last

        expect(provider.ukprn).to eq("00000000")
        expect(provider.seed_data_with_issues).to be(true)
        expect(provider.seed_data_notes.dig("errors", "ukprn"))
          .to include("Not found")
      end
    end

    context "when accreditation number is blank" do
      before { row["accreditation__number"] = nil }

      it "does not create an accreditation" do
        expect { call_importer }.not_to change(Accreditation, :count)
        expect(Provider.last.accreditations).to be_empty
      end
    end

    context "when address is not clean" do
      before { row["found"] = nil }

      it "does not create an address" do
        expect { call_importer }.not_to change(Address, :count)
        expect(Provider.last.addresses).to be_empty
      end
    end

    describe "seed_data_notes" do
      it "records imported row, errors, and saved record IDs" do
        call_importer
        provider = Provider.last
        notes = provider.seed_data_notes

        expect(notes["row_imported"]["raw"]).to eq(row)

        expect(notes["saved_as"]).to match(
          "provider_id" => provider.id,
          "accreditation_id" => provider.accreditations.first.id,
          "address_id" => provider.addresses.first.id,
        )
      end
    end
  end
end
