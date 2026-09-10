RSpec.describe RouteConstraints::ProviderChangeConstraint do
  subject(:matches?) { described_class.new.matches?(request) }

  let(:request) do
    instance_double(
      ActionDispatch::Request,
      path_parameters: { field:, step: }
    )
  end

  context "with a valid field/step combination" do
    let(:field) { "code" }

    %w[
      effective-academic-year
      new-code
      check-your-answers
    ].each do |valid_step|
      context "when step is #{valid_step}" do
        let(:step) { valid_step }

        it { is_expected.to be(true) }
      end
    end
  end

  context "with an invalid step" do
    let(:field) { "code" }
    let(:step) { "invalid_step" }

    it { is_expected.to be(false) }
  end

  context "with an unknown field" do
    let(:field) { "unknown_field" }
    let(:step) { "check-your-answers" }

    it { is_expected.to be(false) }
  end
end
