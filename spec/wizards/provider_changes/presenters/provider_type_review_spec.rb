RSpec.describe ProviderChanges::Presenters::ProviderTypeReview do
  include Rails.application.routes.url_helpers

  subject(:presenter) { described_class.new(wizard) }

  let(:provider) { create(:provider, provider_type: :school) }
  let(:repository) { DfE::Wizard::Repository::InMemory.new }
  let(:state_store) { ProviderChanges::StateStores::ProviderTypeStore.new(repository:) }

  let(:wizard) do
    ProviderChanges::ProviderTypeWizard.new(
      provider: provider,
      current_step: :check_your_answers,
      current_step_params: {},
      state_store: state_store
    )
  end

  before do
    repository.write(
      effective_on: Date.new(2027, 1, 15),
      provider_type: "scitt"
    )
  end

  describe "#rows" do
    it "returns the provider type change details with human labels" do
      expect(presenter.rows.map do |row|
        [row[:key][:text], row[:value][:text]]
      end).to eq(
        [
          ["Old provider type", "School"],
          ["New provider type", "School-centred initial teacher training (SCITT)"],
          ["Effective date", "15 January 2027"],
        ]
      )
    end

    context "when the new provider type is blank" do
      before do
        repository.write(effective_on: Date.new(2027, 1, 15), provider_type: "")
      end

      it "shows the new provider type as not entered" do
        row = presenter.rows.find { |item| item[:key][:text] == "New provider type" }

        expect(row[:value][:text]).to eq("Not entered")
      end
    end
  end

  describe "#format_value" do
    it "formats provider_type through the provider type labels" do
      expect(presenter.format_value(:provider_type, "hei")).to eq("Higher education institution (HEI)")
    end

    it "returns the not entered label for a blank provider type" do
      expect(presenter.format_value(:provider_type, "")).to eq("Not entered")
      expect(presenter.format_value(:provider_type, nil)).to eq("Not entered")
    end

    it "formats effective_on as a readable date" do
      expect(presenter.format_value(:effective_on, Date.new(2028, 3, 2))).to eq("2 March 2028")
    end
  end
end
