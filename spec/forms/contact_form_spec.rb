require "rails_helper"

RSpec.describe ContactForm, type: :model do
  let(:provider) { create(:provider, :hei) }
  let(:valid_attributes) do
    {
      first_name: "Manisha",
      last_name: "Patel",
      email: "manisha@test.org",
      telephone_number: "0121 211 2121",
      provider_id: provider.id
    }
  end

  subject { described_class.new(valid_attributes) }

  describe "validations" do
    it "is valid with complete valid data" do
      expect(subject).to be_valid
    end

    describe "first_name" do
      it "requires first_name" do
        subject.first_name = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:first_name]).to include("Enter first name")
      end

      it "requires first_name to not be blank" do
        subject.first_name = ""
        expect(subject).not_to be_valid
        expect(subject.errors[:first_name]).to include("Enter first name")
      end

      it "validates first_name length" do
        subject.first_name = "a" * 256
        expect(subject).not_to be_valid
        expect(subject.errors[:first_name]).to include("is too long (maximum is 255 characters)")
      end
    end

    describe "last_name" do
      it "requires last_name" do
        subject.last_name = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:last_name]).to include("Enter last name")
      end

      it "requires last_name to not be blank" do
        subject.last_name = ""
        expect(subject).not_to be_valid
      end

      it "validates last_name length" do
        subject.last_name = "a" * 256
        expect(subject).not_to be_valid
        expect(subject.errors[:last_name]).to include("is too long (maximum is 255 characters)")
      end
    end

    describe "email" do
      it "requires email" do
        subject.email = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:email]).to include("Enter email address")
      end

      it "requires email to not be blank" do
        subject.email = ""
        expect(subject).not_to be_valid
        expect(subject.errors[:email]).to include("Enter email address")
      end

      it "validates email length" do
        subject.email = "a" * 256
        expect(subject).not_to be_valid
        expect(subject.errors[:email]).to include("is too long (maximum is 255 characters)")
      end

      it "validates that email has the correct format" do
        subject.email = "invalid-format"
        expect(subject).not_to be_valid
        expect(subject.errors[:email]).to include("Enter an email address in the correct format, like name@example.com")
      end
    end

    describe "telephone_number" do
      it "does not require telephone_number" do
        subject.telephone_number = nil
        expect(subject).to be_valid
      end

      it "allows telephone_number to be blank" do
        subject.telephone_number = ""
        expect(subject).to be_valid
      end

      it "validates telephone_number length" do
        subject.telephone_number = "a" * 256
        expect(subject).not_to be_valid
        expect(subject.errors[:telephone_number]).to include("is too long (maximum is 255 characters)")
      end
    end

    describe "provider_id" do
      it "requires provider_id" do
        subject.provider_id = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:provider_id]).to include("can't be blank")
      end
    end

    context "when Phone number format is invalid" do
      let(:contact) { build(:contact, telephone_number: "invalid") }

      it "is not valid with an invalid email format" do
        expect(contact).not_to be_valid
        expect(contact.errors[:telephone_number]).to include(
          "Enter a phone number, like 01632 960 001, 07700 900 982 or +44 808 157 0192"
        )
      end
    end
  end

  describe "#to_contact_attributes" do
    it "returns address attributes hash" do
      attributes = subject.to_contact_attributes

      expect(attributes).to eq({
        first_name: "Manisha",
        last_name: "Patel",
        email: "manisha@test.org",
        telephone_number: "0121 211 2121",
        provider_id: provider.id
      })
    end
  end

  describe "model naming" do
    it "uses Contact as the model name for form routing" do
      expect(described_class.model_name.name).to eq("Contact")
    end

    it "uses activerecord i18n scope" do
      expect(described_class.i18n_scope).to eq(:activerecord)
    end
  end

  describe ".from_contact" do
    let(:contact) { create(:contact, provider:) }

    it "creates form from existing contact" do
      form = described_class.from_contact(contact)

      expect(form).to be_a(described_class)
      expect(form.first_name).to eq(contact.first_name)
      expect(form.last_name).to eq(contact.last_name)
      expect(form.email).to eq(contact.email)
      expect(form.telephone_number).to eq(contact.telephone_number)
    end

    it "creates valid form from existing contact" do
      form = described_class.from_contact(contact)
      expect(form).to be_valid
    end
  end
end
