RSpec.describe ProviderChanges::Presenters::CodeReview do
  include Rails.application.routes.url_helpers

  subject(:presenter) { described_class.new(wizard) }

  let(:provider) { create(:provider, code: "ABC") }
  let(:repository) { DfE::Wizard::Repository::InMemory.new }
  let(:state_store) { ProviderChanges::StateStores::CodeStore.new(repository:) }

  let(:wizard) do
    ProviderChanges::CodeWizard.new(
      provider: provider,
      current_step: :check_your_answers,
      current_step_params: {},
      state_store: state_store
    )
  end

  before do
    repository.write(
      effective_on: build_academic_year_start_date(2027),
      code: "XYZ"
    )
  end

  describe "#rows" do
    it "returns the provider code change details" do
      expect(presenter.rows.map do |row|
        [row[:key][:text],
         row[:value][:text],]
      end).to eq(
        [
          ["Old provider code", "ABC",],
          ["New provider code", "XYZ",],
          ["Effective on", "2027 to 2028 academic year"],
        ]
      )
    end
  end

  describe "#format_value" do
    it "formats effective_on as an academic year" do
      value = build_academic_year_start_date(2028)

      expect(presenter.format_value(:effective_on, value))
        .to eq("2028 to 2029 academic year")
    end

    it "returns other values unchanged" do
      expect(presenter.format_value(:code, "XYZ")).to eq("XYZ")
    end
  end
end
