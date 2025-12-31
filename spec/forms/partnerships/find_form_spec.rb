require "rails_helper"

RSpec.describe Partnerships::FindForm, type: :model do
  describe "validations" do
    describe "partner_id" do
      it "requires partner_id to be present" do
        form = described_class.new(partner_id: nil)

        expect(form).not_to be_valid
        expect(form.errors[:partner_id]).to include("can't be blank")
      end

      it "requires partner_id to not be blank" do
        form = described_class.new(partner_id: "")

        expect(form).not_to be_valid
        expect(form.errors[:partner_id]).to include("can't be blank")
      end
    end

    describe "partner_must_exist" do
      it "is valid when partner exists" do
        provider = create(:provider)
        form = described_class.new(partner_id: provider.id)

        expect(form).to be_valid
      end

      it "is invalid when partner does not exist" do
        form = described_class.new(partner_id: SecureRandom.uuid)

        expect(form).not_to be_valid
        expect(form.errors[:partner_id]).to include("is invalid")
      end
    end
  end

  describe "attributes" do
    it "has partner_id attribute" do
      form = described_class.new(partner_id: "test-id")

      expect(form.partner_id).to eq("test-id")
    end

    it "has partner_id_raw attribute" do
      form = described_class.new(partner_id_raw: "typed text")

      expect(form.partner_id_raw).to eq("typed text")
    end
  end

  describe ".model_name" do
    it "returns Find for form routing" do
      expect(described_class.model_name.name).to eq("Find")
    end
  end
end

