require "rails_helper"

RSpec.describe Contact, type: :model do
  let(:contact) { create(:contact) }

  it { is_expected.to be_audited }

  describe "associations" do
    it { is_expected.to belong_to(:provider) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.not_to validate_presence_of(:telephone_number) }

    context "when email format is valid" do
      let(:contact) { build(:contact, email: "email@host.org") }

      it "is valid with a valid email format" do
        expect(contact).to be_valid
      end
    end

    context "when email format is invalid" do
      let(:contact) { build(:contact, email: "invalid") }

      it "is not valid with an invalid email format" do
        expect(contact).not_to be_valid
        expect(contact.errors[:email]).to include(
          "Enter an email address in the correct format, like name@example.com"
        )
      end
    end

    context "when email has already been used by another contact" do
      let(:invalid_contact) { build(:contact, email: contact.email, provider: contact.provider) }

      it "is not valid with a non unique email" do
        expect(invalid_contact).not_to be_valid
        expect(invalid_contact.errors[:email]).to include(
          "Email address is already associated with a user, use a different one"
        )
      end
    end

    context "when Phone number format is invalid" do
      let(:contact) { build(:contact, telephone_number: "invalid") }

      it "is not valid with an invalid phone number format" do
        expect(contact).not_to be_valid
        expect(contact.errors[:telephone_number]).to include(
          "Enter a phone number, like 01632 960 001, 07700 900 982 or +44 808 157 0192"
        )
      end
    end
  end

  describe "#full_name" do
    it "shows the contact's full name" do
      expect(contact.full_name).to eq("#{contact.first_name} #{contact.last_name}")
    end
  end

  describe "factory" do
    it "creates a valid contact" do
      expect(contact).to be_valid
      expect(contact).to be_persisted
    end
  end
end
