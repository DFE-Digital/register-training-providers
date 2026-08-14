require "rails_helper"

RSpec.describe DataImporter::ProviderService do
  subject(:call_importer) { described_class.call(row) }

  let!(:prior_academic_year) do
    create(:academic_year, academic_year: AcademicYearCalculator.previous_academic_year - 2)
  end

  let(:base_row) do
    {
      "provider__code" => "W1P",
      "provider__legal_name" => "Legal Name Ltd",
      "provider__operating_name" => "Operating Name",
      "provider__provider_type" => "hei",
      "provider__accreditation_status" => "accredited",
      "provider__ukprn" => "12345678",
      "provider__urn" => "876543",
      "provider__academic_years_active" => "#{AcademicYearCalculator.current_academic_year},#{AcademicYearCalculator.previous_academic_year},#{AcademicYearCalculator.previous_academic_year - 2}",
      "accreditation__number" => "1001",
      "accreditation__start_date" => "2024-01-01",
      "accreditation__end_date" => "#{AcademicYearCalculator.next_academic_year}-08-01",
      "address__postcode" => "SW1A 1AA",
      "address__address_line_1" => "10 Downing Street",
      "address__town_or_city" => "London",
      "address__county" => "Greater London",
      "address__uprn" => "100023336956",
      "address__latitude" => "51.5033635",
      "address__longitude" => "-0.1276248",
      "address__found" => "true"
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
      it "creates a provider with correct attributes" do
        expect { call_importer }
          .to change(Provider, :count).by(1)

        provider = Provider.last

        expect(provider).to have_attributes(
          code: "W1P",
          legal_name: "Legal Name Ltd",
          operating_name: "Operating Name",
          provider_type: "hei",
          accreditation_status: "accredited",
          ukprn: "12345678",
          urn: "876543"
        )
      end

      it "creates an accreditation" do
        expect { call_importer }
          .to change(Accreditation, :count).by(1)

        accreditation = Accreditation.last

        expect(accreditation).to have_attributes(
          number: "1001",
          start_date: Date.parse("2024-01-01"),
          end_date: Date.parse("#{AcademicYearCalculator.next_academic_year}-08-01")
        )
      end

      it "creates an address" do
        expect { call_importer }
          .to change(Address, :count).by(1)

        address = Address.last

        expect(address).to have_attributes(
          postcode: "SW1A 1AA",
          address_line_1: "10 Downing Street",
          town_or_city: "London",
          county: "Greater London",
          uprn: "100023336956"
        )
      end

      it "sets lifecycle dates correctly" do
        call_importer
        provider = Provider.last

        expect(provider.onboarded_at).to eq(Date.new(AcademicYearCalculator.previous_academic_year - 2, 8, 1))
        expect(provider.first_active_at).to eq(Date.new(AcademicYearCalculator.previous_academic_year - 2, 8, 1))
        expect(provider.inactive_periods).to be_present
      end

      it "associates academic years" do
        call_importer
        provider = Provider.last

        expect(provider.academic_years.count).to eq(3)
      end

      it "generates a rotp_id" do
        call_importer
        provider = Provider.last

        expect(provider.rotp_id).to be_present
        expect(provider.rotp_id).to start_with("RoTP-")
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
            "accreditation__number" => "5001"
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

      it "does not create duplicate accreditations" do
        create(:accreditation, provider: provider, number: "1001")

        expect { call_importer }.not_to change(Accreditation, :count)
      end

      it "does not create duplicate addresses" do
        create(:address, provider: provider, postcode: "SW1A 1AA")

        expect { call_importer }.not_to change(Address, :count)
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

    context "when UKPRN is 'not found'" do
      before { row["provider__ukprn"] = "not found" }

      it "uses the default UKPRN" do
        call_importer
        expect(Provider.last.ukprn).to eq("00000000")
      end
    end

    context "when accreditation_status is unaccredited" do
      before { row["provider__accreditation_status"] = "unaccredited" }

      it "does not create an accreditation" do
        expect { call_importer }.not_to change(Accreditation, :count)
        expect(Provider.last.accreditations).to be_empty
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
      before { row["address__found"] = nil }

      it "does not create an address" do
        expect { call_importer }.not_to change(Address, :count)
        expect(Provider.last.addresses).to be_empty
      end
    end

    context "when postcode is missing" do
      before { row["address__postcode"] = nil }

      it "does not create an address" do
        expect { call_importer }.not_to change(Address, :count)
      end
    end

    context "when address__found is false" do
      before { row["address__found"] = "false" }

      it "does not create an address" do
        expect { call_importer }.not_to change(Address, :count)
      end
    end

    describe "seed_data_notes" do
      it "records imported row data" do
        call_importer
        provider = Provider.last
        notes = provider.seed_data_notes

        expect(notes["row_imported"]["raw"]).to eq(row)
        expect(notes["row_imported"]["provider"]).to include(
          "code" => "W1P",
          "legal_name" => "Legal Name Ltd"
        )
      end

      it "records saved record IDs" do
        call_importer
        provider = Provider.last
        notes = provider.seed_data_notes

        expect(notes["saved_as"]["provider_id"]).to eq(provider.id)
        expect(notes["saved_as"]["accreditation_id"]).to eq(provider.accreditations.first.id)
        expect(notes["saved_as"]["address_id"]).to eq(provider.addresses.first.id)
      end

      it "records errors when they exist" do
        row["provider__ukprn"] = nil
        call_importer
        provider = Provider.last

        expect(provider.seed_data_notes["errors"]).to include("ukprn")
      end

      it "sets seed_data_with_issues flag when errors exist" do
        row["provider__ukprn"] = nil
        call_importer
        provider = Provider.last

        expect(provider.seed_data_with_issues).to be(true)
      end

      context "when there are no errors" do
        it "sets seed_data_with_issues to false" do
          call_importer
          provider = Provider.last

          expect(provider.seed_data_with_issues).to be(false)
        end
      end
    end

    describe "academic years" do
      context "when academic_years_active contains multiple years" do
        it "associates all academic years" do
          call_importer
          provider = Provider.last

          expect(provider.academic_years.count).to eq(3)
        end
      end

      context "when academic_years_active is a single year" do
        before do
          row["provider__academic_years_active"] = AcademicYearCalculator.current_academic_year.to_s
        end

        it "associates the single academic year" do
          call_importer
          provider = Provider.last

          expect(provider.academic_years.count).to eq(1)
        end
      end
    end
  end
end
