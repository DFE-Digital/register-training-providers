require "rails_helper"

RSpec.describe Generators::Accreditations, type: :service do
  describe "#call" do
    let!(:hei_provider) { create(:provider, :hei, accreditation_status: :accredited, with_accreditations: false) }
    let!(:scitt_provider) { create(:provider, provider_type: :scitt, accreditation_status: :accredited) }
    let!(:other_provider) { create(:provider, :other, accreditation_status: :accredited) }
    let!(:school_provider) { create(:provider, :school) }

    subject { described_class.call(percentage: 1.0) }

    it "generates accreditations for every provider type" do
      expect { subject }.to(change { Accreditation.count })

      expect(hei_provider.reload.accreditations).to be_present
      expect(scitt_provider.reload.accreditations).to be_present
      expect(other_provider.reload.accreditations).to be_present
      expect(school_provider.reload.accreditations).to be_present
    end

    it "returns the service instance with results" do
      result = subject

      expect(result).to be_a(Generators::Accreditations)
      expect(result.total_accreditable).to eq(4)
      expect(result.providers_accredited).to eq(4)
    end

    it "generates correct accreditation number prefixes" do
      expect(hei_provider.accreditations).to be_empty

      subject

      hei_accreditation = hei_provider.reload.accreditations.first
      scitt_accreditation = scitt_provider.reload.accreditations.first
      school_accreditation = school_provider.reload.accreditations.first

      expect(hei_accreditation.number).to start_with("1")
      expect(scitt_accreditation.number).to start_with("5")
      expect(school_accreditation.number).to start_with("5")
      expect(hei_accreditation.number).to match(/\A1\d{3}\z/)
      expect(scitt_accreditation.number).to match(/\A5\d{3}\z/)
      expect(school_accreditation.number).to match(/\A5\d{3}\z/)
    end

    it "creates valid date ranges for accreditations" do
      subject

      hei_provider.reload.accreditations.each do |accreditation|
        expect(accreditation.start_date).to be_present
        expect(accreditation.start_date).to be <= Date.current
      end
    end
  end
end
