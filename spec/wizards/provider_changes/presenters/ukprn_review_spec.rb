RSpec.describe ProviderChanges::Presenters::UkprnReview do
  include Rails.application.routes.url_helpers

  subject(:presenter) { described_class.new(wizard) }

  let(:provider) { create(:provider, ukprn: "11111111") }
  let(:repository) { DfE::Wizard::Repository::InMemory.new }
  let(:state_store) { ProviderChanges::StateStores::UkprnStore.new(repository:) }

  let(:wizard) do
    ProviderChanges::UkprnWizard.new(
      provider: provider,
      current_step: :check_your_answers,
      current_step_params: {},
      state_store: state_store
    )
  end

  before do
    repository.write(
      effective_on: Date.new(2027, 1, 15),
      ukprn: "22222222"
    )
  end

  describe "#rows" do
    it "returns the UKPRN change details" do
      expect(presenter.rows.map do |row|
        [row[:key][:text], row[:value][:text]]
      end).to eq(
        [
          ["Old UK provider reference number (UKPRN)", "11111111"],
          ["New UK provider reference number (UKPRN)", "22222222"],
          ["Effective date", "15 January 2027"],
        ]
      )
    end
  end

  describe "#format_value" do
    it "formats effective_on as a readable date" do
      expect(presenter.format_value(:effective_on, Date.new(2028, 3, 2))).to eq("2 March 2028")
    end

    it "returns other values unchanged" do
      expect(presenter.format_value(:ukprn, "22222222")).to eq("22222222")
    end
  end
end
