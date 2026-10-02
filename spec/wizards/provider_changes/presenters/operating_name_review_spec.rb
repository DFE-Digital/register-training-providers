RSpec.describe ProviderChanges::Presenters::OperatingNameReview do
  include Rails.application.routes.url_helpers

  subject(:presenter) { described_class.new(wizard) }

  let(:provider) { create(:provider, operating_name: "Old provider name") }
  let(:repository) { DfE::Wizard::Repository::InMemory.new }
  let(:state_store) { ProviderChanges::StateStores::OperatingNameStore.new(repository:) }

  let(:wizard) do
    ProviderChanges::OperatingNameWizard.new(
      provider: provider,
      current_step: :check_your_answers,
      current_step_params: {},
      state_store: state_store
    )
  end

  before do
    repository.write(
      effective_on: Date.new(2027, 1, 15),
      operating_name: "New provider name"
    )
  end

  describe "#rows" do
    it "returns the operating name change details" do
      expect(presenter.rows.map do |row|
        [row[:key][:text], row[:value][:text]]
      end).to eq(
        [
          ["Old operating name", "Old provider name"],
          ["New operating name", "New provider name"],
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
      expect(presenter.format_value(:operating_name, "New provider name")).to eq("New provider name")
    end
  end
end
