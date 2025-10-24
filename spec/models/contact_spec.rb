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
    it { is_expected.to validate_presence_of(:email_address) }
    it { is_expected.to validate_presence_of(:telephone_number) }
  end

  describe "factory" do
    it "creates a valid contact" do
      expect(contact).to be_valid
      expect(contact).to be_persisted
    end
  end
end
