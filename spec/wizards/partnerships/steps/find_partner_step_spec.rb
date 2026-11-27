require "rails_helper"

RSpec.describe Partnerships::Steps::FindPartnerStep do
  subject(:step) { described_class.new(partner_id:, wizard:) }

  let(:provider) { create(:provider, :accredited) }
  let(:eligible_partners) do
    provider.accredited? ? Provider.kept.unaccredited : Provider.kept.accredited
  end
  let(:wizard) { instance_double(Partnerships::AddWizard, provider:, eligible_partners:) }
  let(:partner_id) { nil }

  it "requires a partner to be selected" do
    expect(step).not_to be_valid
    expect(step.errors[:partner_id]).to include(
      I18n.t("activerecord.errors.models.find.attributes.partner_id.blank_training_partner")
    )
  end

  context "when the provider is not accredited" do
    let(:provider) { create(:provider, :hei_without_accreditation) }

    it "uses the accredited provider wording" do
      expect(step).not_to be_valid
      expect(step.errors[:partner_id]).to include(
        I18n.t("activerecord.errors.models.find.attributes.partner_id.blank_accredited_provider")
      )
    end
  end

  context "when the partner does not exist" do
    let(:partner_id) { SecureRandom.uuid }

    it "rejects an unknown partner" do
      expect(step).not_to be_valid
      expect(step.errors[:partner_id]).to be_present
    end
  end

  context "when the partner exists" do
    let(:partner_id) { create(:provider, :hei_without_accreditation).id }

    it { is_expected.to be_valid }
  end

  describe ".permitted_params" do
    it { expect(described_class.permitted_params).to eq(%i[partner_id]) }
  end
end
