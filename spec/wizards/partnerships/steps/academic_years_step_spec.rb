require "rails_helper"

RSpec.describe Partnerships::Steps::AcademicYearsStep do
  subject(:step) { described_class.new(academic_year_ids:) }

  let(:academic_year_ids) { [] }

  it "requires at least one academic year" do
    expect(step).not_to be_valid
    expect(step.errors[:academic_year_ids]).to include(
      I18n.t("activerecord.errors.models.academic_years.attributes.academic_year_ids.blank")
    )
  end

  context "when academic years are selected" do
    let(:academic_year_ids) { [create(:academic_year).id] }

    it { is_expected.to be_valid }
  end

  context "when the selection contains blank values" do
    let(:academic_year_ids) { ["", create(:academic_year).id] }

    it { is_expected.to be_valid }
  end

  describe ".permitted_params" do
    it "permits an array of academic year ids" do
      expect(described_class.permitted_params).to eq([{ academic_year_ids: [] }])
    end
  end
end
