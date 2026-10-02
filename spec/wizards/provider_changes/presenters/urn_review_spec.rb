RSpec.describe ProviderChanges::Presenters::UrnReview do
  include Rails.application.routes.url_helpers

  subject(:presenter) { described_class.new(wizard) }

  let(:provider) { create(:provider, urn: "111111") }
  let(:repository) { DfE::Wizard::Repository::InMemory.new }
  let(:state_store) { ProviderChanges::StateStores::UrnStore.new(repository:) }

  let(:wizard) do
    ProviderChanges::UrnWizard.new(
      provider: provider,
      current_step: :check_your_answers,
      current_step_params: {},
      state_store: state_store
    )
  end

  before do
    repository.write(
      effective_on: Date.new(2027, 1, 15),
      urn: "222222"
    )
  end

  describe "#rows" do
    it "returns the URN change details" do
      expect(presenter.rows.map do |row|
        [row[:key][:text], row[:value][:text]]
      end).to eq(
        [
          ["Old unique reference number (URN)", "111111"],
          ["New unique reference number (URN)", "222222"],
          ["Effective date", "15 January 2027"],
        ]
      )
    end

    context "when the provider has no URN" do
      let(:provider) { create(:provider, :hei, urn: nil) }

      it "shows the old URN as not entered" do
        expect(presenter.rows.first).to eq(
          key: { text: "Old unique reference number (URN)" },
          value: { text: "Not entered" }
        )
      end
    end
  end

  describe "#format_value" do
    it "formats effective_on as a readable date" do
      expect(presenter.format_value(:effective_on, Date.new(2028, 3, 2))).to eq("2 March 2028")
    end

    it "returns other values unchanged" do
      expect(presenter.format_value(:urn, "222222")).to eq("222222")
    end

    it "returns the not entered label for a blank URN" do
      expect(presenter.format_value(:urn, "")).to eq("Not entered")
      expect(presenter.format_value(:urn, nil)).to eq("Not entered")
    end
  end
end
