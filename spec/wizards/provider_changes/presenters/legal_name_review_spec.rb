RSpec.describe ProviderChanges::Presenters::LegalNameReview do
  include Rails.application.routes.url_helpers

  subject(:presenter) { described_class.new(wizard) }

  let(:provider) { create(:provider, legal_name: "Old provider name") }
  let(:repository) { DfE::Wizard::Repository::InMemory.new }
  let(:state_store) { ProviderChanges::StateStores::LegalNameStore.new(repository:) }

  let(:wizard) do
    ProviderChanges::LegalNameWizard.new(
      provider: provider,
      current_step: :check_your_answers,
      current_step_params: {},
      state_store: state_store
    )
  end

  before do
    repository.write(
      effective_on: Date.new(2027, 1, 15),
      legal_name: "New provider name"
    )
  end

  describe "#rows" do
    it "returns the legal name change details" do
      expect(presenter.rows.map do |row|
        [row[:key][:text], row[:value][:text]]
      end).to eq(
        [
          ["Old legal name", "Old provider name"],
          ["New legal name", "New provider name"],
          ["Effective date", "15 January 2027"],
        ]
      )
    end

    context "when the provider has no legal name" do
      let(:provider) { create(:provider, operating_name: "Provider without legal name", legal_name: nil) }

      it "shows the old legal name as not entered" do
        expect(presenter.rows.first).to eq(
          key: { text: "Old legal name" },
          value: { text: "Not entered" }
        )
      end
    end

    context "when the new legal name is blank" do
      before do
        repository.write(effective_on: Date.new(2027, 1, 15), legal_name: "")
      end

      it "shows the new legal name as not entered" do
        row = presenter.rows.find { |item| item[:key][:text] == "New legal name" }

        expect(row[:value][:text]).to eq("Not entered")
      end
    end
  end

  describe "#format_value" do
    it "formats effective_on as a readable date" do
      expect(presenter.format_value(:effective_on, Date.new(2028, 3, 2))).to eq("2 March 2028")
    end

    it "returns other values unchanged" do
      expect(presenter.format_value(:legal_name, "New provider name")).to eq("New provider name")
    end

    it "returns the not entered label for a blank legal name" do
      expect(presenter.format_value(:legal_name, "")).to eq("Not entered")
      expect(presenter.format_value(:legal_name, nil)).to eq("Not entered")
    end
  end
end
