require "rails_helper"

RSpec.describe Partnerships::Steps::EndDateQuestionStep do
  subject(:step) { described_class.new(has_end_date:) }

  let(:has_end_date) { "true" }

  it { is_expected.to be_valid }

  context "when the answer is no" do
    let(:has_end_date) { "false" }

    it { is_expected.to be_valid }
  end

  context "when no answer is given" do
    let(:has_end_date) { nil }

    it "is invalid" do
      expect(step).not_to be_valid
      expect(step.errors[:has_end_date]).to include(
        I18n.t("activerecord.errors.models.partnerships/end_date_question_step.attributes.has_end_date.inclusion")
      )
    end
  end
end
