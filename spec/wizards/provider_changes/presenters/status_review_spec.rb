RSpec.describe ProviderChanges::Presenters::StatusReview do
  include Rails.application.routes.url_helpers

  subject(:presenter) { described_class.new(wizard) }

  let(:provider) { create(:provider) }
  let(:repository) { DfE::Wizard::Repository::InMemory.new }
  let(:state_store) { ProviderChanges::StateStores::StatusStore.new(repository:) }

  let(:wizard) do
    ProviderChanges::StatusWizard.new(
      provider: provider,
      current_step: :check_your_answers,
      current_step_params: {},
      state_store: state_store
    )
  end

  before do
    repository.write(
      new_status: "inactive",
      reasons: ["no_current_cohorts"],
      effective_on: Date.new(2027, 1, 15)
    )
  end

  describe "#rows" do
    it "returns the status change details" do
      expect(presenter.rows.map do |row|
        [row[:key][:text], row[:value][:text]]
      end).to eq(
        [
          ["Current status", "Active"],
          ["New status", "Inactive"],
          ["Reason", "No current cohorts"],
          ["Effective date", "15 January 2027"]
        ]
      )
    end

    it "links the change actions back to their steps" do
      expect(presenter.rows.filter_map { |row| row[:actions]&.first })
        .to all(include(:href, :visually_hidden_text))

      expect(presenter.rows.second[:actions]).to eq(
        [
          {
            href: provider_change_update_step_path(provider_id: provider.id, field: "status", step: "new-status", return_to_review: :new_status),
            visually_hidden_text: "new status"
          }
        ]
      )
    end
  end

  context "when the new status is active" do
    before do
      repository.write(new_status: "active")
    end

    it "omits the reason row" do
      expect(presenter.rows.map { |row| row[:key][:text] }).to eq(
        ["Current status", "New status", "Effective date"]
      )
    end

    it "formats the new status as a label" do
      expect(presenter.rows.second[:value][:text]).to eq("Active")
    end

    context "when no effective date was captured" do
      before do
        repository.write(effective_on: nil)
      end

      it "keeps the effective date row blank" do
        expect(presenter.rows.third[:value][:text]).to eq("")
      end
    end
  end

  context "when the provider is currently inactive" do
    before do
      provider.inactive_periods << { "start_date" => "2026-09-01", "end_date" => nil }
      provider.save!
    end

    it "shows the current status" do
      expect(presenter.rows.first[:value][:text]).to eq("Inactive")
    end
  end
end
