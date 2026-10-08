require "rails_helper"

RSpec.describe ProviderCreation::SessionManager do
  subject(:manager) { described_class.new(session) }

  let(:session) { {} }

  describe "#store_provider_type" do
    it "stores the authoritative provider type and accreditation status" do
      manager.store_provider_type("provider_type" => "school", "accreditation_status" => "accredited")

      expect(manager.load_provider_type).to eq(
        "provider_type" => "school", "accreditation_status" => "accredited"
      )
    end

    it "keeps a stored provider row in sync when the type changes" do
      manager.store_provider(
        "operating_name" => "Test Provider",
        "provider_type" => "hei",
        "accreditation_status" => "unaccredited"
      )

      manager.store_provider_type("provider_type" => "scitt", "accreditation_status" => "accredited")

      provider = manager.load_provider
      expect(provider.provider_type).to eq("scitt")
      expect(provider.accreditation_status).to eq("accredited")
      expect(provider.operating_name).to eq("Test Provider")
    end
  end

  describe "#clear_provider_type" do
    it "clears the stored type and the provider row's type and status" do
      manager.store_provider(
        "operating_name" => "Test Provider",
        "provider_type" => "hei",
        "accreditation_status" => "unaccredited"
      )
      manager.store_provider_type("provider_type" => "hei", "accreditation_status" => "unaccredited")

      manager.clear_provider_type

      expect(manager.load_provider_type).to be_nil

      provider = manager.load_provider
      expect(provider.provider_type).to be_nil
      expect(provider.accreditation_status).to be_nil
      expect(provider.operating_name).to eq("Test Provider")
    end
  end

  describe "#clear_accreditation" do
    it "clears the stored accreditation payload" do
      manager.store_accreditation("number" => "1234")

      manager.clear_accreditation

      expect(manager.load_accreditation).to be_nil
    end
  end
end
