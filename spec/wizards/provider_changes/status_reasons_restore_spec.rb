require "rails_helper"

RSpec.describe "status reasons pending-restore (regression)", type: :model do
  it "keeps the captured reasons intact when a pending change is restored into the wizard" do
    provider = create(:provider)
    provider.provider_changes.create!(
      attribute_name: "status",
      value: { "status" => "inactive", "reason_ids" => %w[no_current_cohorts other], "other_reason" => "Custom reason" },
      effective_on: Date.current + 3.months
    )
    pending_change = provider.provider_changes.pending.for_attribute("status").sole

    repository = DfE::Wizard::Repository::InMemory.new
    state_store = ProviderChanges::StateStores::StatusStore.new(repository:)
    wizard = ProviderChanges::StatusWizard.new(
      provider: provider,
      current_step: :new_status,
      current_step_params: {},
      state_store: state_store
    )

    wizard.set_state_store(pending_change)

    expect(wizard.provider_change_attributes).to eq(
      attribute_name: "status",
      effective_on: pending_change.effective_on,
      value: {
        "status" => "inactive",
        "reason_ids" => %w[no_current_cohorts other],
        "other_reason" => "Custom reason"
      }
    )
    expect(wizard.step(:reasons)).to be_valid
  end
end
