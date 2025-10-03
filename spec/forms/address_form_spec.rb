require "rails_helper"

RSpec.describe AddressForm, type: :model do
  let(:provider) { create(:provider, :hei) }
  let(:valid_attributes) do
    {
      address_line_1: "123 Test Street",
      address_line_2: "Test Building",
      address_line_3: "Test Floor",
      town_or_city: "Test City",
      county: "Test County",
      postcode: "SW1A 1AA",
      provider_id: provider.id
    }
  end

  subject { described_class.new(valid_attributes) }

  describe "validations" do
    it "is valid with complete valid data" do
      expect(subject).to be_valid
    end

    it "is valid with only required fields" do
      minimal_form = described_class.new(
        address_line_1: "123 Test Street",
        town_or_city: "Test City",
        postcode: "SW1A 1AA",
        provider_id: provider.id
      )
      expect(minimal_form).to be_valid
    end

    describe "address_line_1" do
      it "requires address_line_1" do
        subject.address_line_1 = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:address_line_1]).to include("Enter address line 1, typically the building and street")
      end

      it "requires address_line_1 to not be blank" do
        subject.address_line_1 = ""
        expect(subject).not_to be_valid
        expect(subject.errors[:address_line_1]).to include("Enter address line 1, typically the building and street")
      end

      it "validates address_line_1 length" do
        subject.address_line_1 = "a" * 256
        expect(subject).not_to be_valid
        expect(subject.errors[:address_line_1]).to include("is too long (maximum is 255 characters)")
      end
    end

    describe "address_line_2" do
      it "allows address_line_2 to be blank" do
        subject.address_line_2 = nil
        expect(subject).to be_valid
      end

      it "validates address_line_2 length" do
        subject.address_line_2 = "a" * 256
        expect(subject).not_to be_valid
        expect(subject.errors[:address_line_2]).to include("is too long (maximum is 255 characters)")
      end
    end

    describe "address_line_3" do
      it "allows address_line_3 to be blank" do
        subject.address_line_3 = nil
        expect(subject).to be_valid
      end

      it "validates address_line_3 length" do
        subject.address_line_3 = "a" * 256
        expect(subject).not_to be_valid
        expect(subject.errors[:address_line_3]).to include("is too long (maximum is 255 characters)")
      end
    end

    describe "town_or_city" do
      it "requires town_or_city" do
        subject.town_or_city = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:town_or_city]).to include("Enter town or city")
      end

      it "requires town_or_city to not be blank" do
        subject.town_or_city = ""
        expect(subject).not_to be_valid
        expect(subject.errors[:town_or_city]).to include("Enter town or city")
      end

      it "validates town_or_city length" do
        subject.town_or_city = "a" * 256
        expect(subject).not_to be_valid
        expect(subject.errors[:town_or_city]).to include("is too long (maximum is 255 characters)")
      end
    end

    describe "county" do
      it "allows county to be blank" do
        subject.county = nil
        expect(subject).to be_valid
      end

      it "validates county length" do
        subject.county = "a" * 256
        expect(subject).not_to be_valid
        expect(subject.errors[:county]).to include("is too long (maximum is 255 characters)")
      end
    end

    describe "postcode" do
      it "requires postcode" do
        subject.postcode = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:postcode]).to include("Enter postcode")
      end

      it "requires postcode to not be blank" do
        subject.postcode = ""
        expect(subject).not_to be_valid
        expect(subject.errors[:postcode]).to include("Enter postcode")
      end

      it "validates valid UK postcode formats" do
        valid_postcodes = ["SW1A 1AA", "M1 1AA", "B33 8TH", "W1A 0AX", "EC1A 1BB"]

        valid_postcodes.each do |postcode|
          subject.postcode = postcode
          expect(subject).to be_valid, "Expected #{postcode} to be valid"
        end
      end

      it "rejects invalid postcode formats" do
        invalid_postcodes = ["12345", "ABC", "SW1A1AA1"]

        invalid_postcodes.each do |postcode|
          subject.postcode = postcode
          expect(subject).not_to be_valid, "Expected #{postcode} to be invalid"
          expect(subject.errors[:postcode]).to include("Enter a full UK postcode")
        end
      end

      it "normalizes postcode to uppercase" do
        subject.postcode = "sw1a 1aa"
        subject.valid?
        expect(subject.postcode).to eq("SW1A 1AA")
      end

      it "strips whitespace from postcode" do
        subject.postcode = "  SW1A 1AA  "
        subject.valid?
        expect(subject.postcode).to eq("SW1A 1AA")
      end
    end

    describe "provider_id" do
      it "requires provider_id" do
        subject.provider_id = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:provider_id]).to include("can't be blank")
      end
    end
  end

  describe "#to_address_attributes" do
    it "returns address attributes hash" do
      attributes = subject.to_address_attributes

      expect(attributes).to eq({
        address_line_1: "123 Test Street",
        address_line_2: "Test Building",
        address_line_3: "Test Floor",
        town_or_city: "Test City",
        county: "Test County",
        postcode: "SW1A 1AA",
        provider_id: provider.id
      })
    end

    it "compacts nil values" do
      minimal_form = described_class.new(
        address_line_1: "123 Test Street",
        town_or_city: "Test City",
        postcode: "SW1A 1AA",
        provider_id: provider.id
      )

      attributes = minimal_form.to_address_attributes

      expect(attributes).to eq({
        address_line_1: "123 Test Street",
        town_or_city: "Test City",
        postcode: "SW1A 1AA",
        provider_id: provider.id
      })
    end
  end

  describe "model naming" do
    it "uses Address as the model name for form routing" do
      expect(described_class.model_name.name).to eq("Address")
    end

    it "uses activerecord i18n scope" do
      expect(described_class.i18n_scope).to eq(:activerecord)
    end
  end

  describe "normalization" do
    it "normalizes postcode before validation" do
      form = described_class.new(valid_attributes.merge(postcode: "  sw1a 1aa  "))
      form.valid?
      expect(form.postcode).to eq("SW1A 1AA")
    end

    it "handles nil postcode gracefully" do
      form = described_class.new(valid_attributes.merge(postcode: nil))
      expect { form.valid? }.not_to raise_error
    end

    it "handles blank postcode gracefully" do
      form = described_class.new(valid_attributes.merge(postcode: ""))
      expect { form.valid? }.not_to raise_error
    end
  end

  describe ".from_address" do
    let(:address) { create(:address, provider:) }

    it "creates form from existing address" do
      form = described_class.from_address(address)

      expect(form).to be_a(described_class)
      expect(form.address_line_1).to eq(address.address_line_1)
      expect(form.address_line_2).to eq(address.address_line_2)
      expect(form.address_line_3).to eq(address.address_line_3)
      expect(form.town_or_city).to eq(address.town_or_city)
      expect(form.county).to eq(address.county)
      expect(form.postcode).to eq(address.postcode)
      expect(form.provider_id).to eq(address.provider_id)
    end

    it "creates valid form from existing address" do
      form = described_class.from_address(address)
      expect(form).to be_valid
    end
  end
end
