# spec/services/provider_xlsx_row_importer_spec.rb
require "rails_helper"

RSpec.describe ProviderXlsxRowImporter do
  let(:row) do
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
      "accreditation__end_date" => "2026-01-01"
    }
  end

  describe ".call" do
    it "calls the instance method" do
      importer = instance_double(described_class)
      expect(described_class).to receive(:new).with(row).and_return(importer)
      expect(importer).to receive(:call)
      described_class.call(row)
    end
  end

  describe "#call" do
    context "when provider does not exist" do
      it "creates a new provider with attributes" do
        expect {
          described_class.call(row)
        }.to change(Provider, :count).by(1)

        provider = Provider.last
        expect(provider.code).to eq("W1P")
        expect(provider.legal_name).to eq("Legal Name Ltd")
        expect(provider.provider_type).to eq("hei")
        expect(provider.accreditations.count).to eq(1)
      end
    end

    context "when provider already exists" do
      let!(:provider) { create(:provider, code: "W1P") }

      it "updates existing provider" do
        described_class.call(row)
        provider.reload

        expect(provider.legal_name).to eq("Legal Name Ltd")
        expect(provider.operating_name).to eq("Operating Name")
      end
    end

    context "with missing UKPRN" do
      before { row["provider__ukprn"] = nil }

      it "sets default UKPRN and adds error" do
        described_class.call(row)
        provider = Provider.last
        expect(provider.ukprn).to eq("00000000")
        expect(provider.seed_data_notes["errors"]["ukprn"]).to include("Not found")
        expect(provider.seed_data_with_issues).to be true
      end
    end

    context "with blank accreditation number" do
      before { row["accreditation__number"] = nil }

      it "does not create an accreditation" do
        expect {
          described_class.call(row)
        }.not_to change(Accreditation, :count)
      end
    end

    it "attaches seed data notes with row and errors" do
      described_class.call(row)
      provider = Provider.last
      expect(provider.seed_data_notes["row_imported"]["raw"]).to eq(row)
      expect(provider.seed_data_notes["errors"]).to be_a(Hash)
    end
  end
end
