require "rails_helper"

RSpec.describe Partnerships::Steps::TypesStep do
  subject(:step) { described_class.new(partnership_types:, wizard:) }

  let(:wizard) do
    instance_double(
      Partnerships::AddWizard,
      available_partnership_types: %w[recruitment training_and_delivery],
      used_partnership_types: %w[student_fee_management],
      placement_available?: false
    )
  end
  let(:partnership_types) { [] }

  it "requires at least one partnership type" do
    expect(step).not_to be_valid
    expect(step.errors[:partnership_types]).to include(
      I18n.t("activerecord.errors.models.partnerships/types_step.attributes.partnership_types.blank")
    )
  end

  context "when a blank option is submitted alongside a real one" do
    let(:partnership_types) { ["", "recruitment"] }

    it { is_expected.to be_valid }
  end

  context "when the selection contains a type that is not available" do
    let(:partnership_types) { ["placement"] }

    it "rejects it" do
      expect(step).not_to be_valid
      expect(step.errors[:partnership_types]).to include(
        I18n.t("activerecord.errors.models.partnerships/types_step.attributes.partnership_types.inclusion")
      )
    end
  end

  context "when the selection contains a type already used with the partner" do
    let(:partnership_types) { ["student_fee_management"] }

    it { is_expected.not_to be_valid }
  end

  describe ".permitted_params" do
    it { expect(described_class.permitted_params).to eq([{ partnership_types: [] }]) }
  end
end
