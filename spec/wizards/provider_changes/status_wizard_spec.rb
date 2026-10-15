RSpec.describe ProviderChanges::StatusWizard do
  include Rails.application.routes.url_helpers

  subject(:wizard) do
    described_class.new(
      provider:,
      current_step:,
      current_step_params:,
      state_store:
    )
  end

  let(:provider) { create(:provider) }
  let(:current_step) { :new_status }
  let(:current_step_params) { {} }
  let(:effective_on) { Date.new(2027, 1, 15) }

  let(:repository) { DfE::Wizard::Repository::InMemory.new }

  let(:state_store) do
    ProviderChanges::StateStores::StatusStore.new(repository:)
  end

  describe "step graph" do
    it { is_expected.to have_root_step(:new_status) }

    context "when the new status captures reasons" do
      before do
        state_store.write(new_status: "inactive")
      end

      it do
        expect(wizard)
          .to have_next_step(:reasons)
          .from(:new_status)
      end

      it do
        expect(wizard)
          .to have_next_step(:effective_date)
          .from(:reasons)
      end
    end

    context "when the new status does not capture reasons" do
      before do
        state_store.write(new_status: "active")
      end

      it do
        expect(wizard)
          .to have_next_step(:effective_date)
          .from(:new_status)
      end

      it do
        expect(wizard)
          .to have_previous_step(:new_status)
          .from(:effective_date)
      end
    end

    it do
      expect(wizard)
        .to have_next_step(:check_your_answers)
        .from(:effective_date)
    end

    it do
      expect(wizard)
        .to have_next_step(nil)
        .from(:check_your_answers)
    end
  end

  describe "routes" do
    it "routes new_status" do
      expect(wizard).to resolve_step(:new_status).to(
        provider_change_update_step_path(
          provider_id: provider.id,
          field: "status",
          step: "new-status"
        )
      )
    end

    it "routes reasons" do
      expect(wizard).to resolve_step(:reasons).to(
        provider_change_update_step_path(
          provider_id: provider.id,
          field: "status",
          step: "reasons"
        )
      )
    end

    it "routes effective_date" do
      expect(wizard).to resolve_step(:effective_date).to(
        provider_change_update_step_path(
          provider_id: provider.id,
          field: "status",
          step: "effective-date"
        )
      )
    end

    it "routes check_your_answers" do
      expect(wizard).to resolve_step(:check_your_answers).to(
        provider_change_update_step_path(
          provider_id: provider.id,
          field: "status",
          step: "check-your-answers"
        )
      )
    end
  end

  describe "review navigation" do
    before do
      state_store.write(
        effective_on: effective_on,
        new_status: "inactive",
        reasons: ["no_current_cohorts"]
      )
    end

    context "when returning to review" do
      let(:current_step_params) { { return_to_review: "new_status" } }

      it "goes to check your answers" do
        expect(wizard.next_step).to eq(:check_your_answers)
      end
    end

    context "when returning from review" do
      let(:current_step) { :effective_date }
      let(:current_step_params) { { return_to_review: "effective_date" } }

      it "goes to check your answers" do
        expect(wizard.previous_step).to eq(:check_your_answers)
      end
    end
  end

  describe "check_your_answers?" do
    context "when current_step is new_status" do
      it "returns false" do
        expect(wizard.check_your_answers?).to be(false)
      end
    end

    context "when current_step is reasons" do
      let(:current_step) { :reasons }

      it "returns false" do
        expect(wizard.check_your_answers?).to be(false)
      end
    end

    context "when current_step is check_your_answers" do
      let(:current_step) { :check_your_answers }

      it "returns true" do
        expect(wizard.check_your_answers?).to be(true)
      end
    end
  end

  describe "#set_state_store" do
    let(:provider_change) do
      create(
        :provider_change,
        provider: provider,
        attribute_name: "status",
        value: {
          "status" => "inactive",
          "reason_ids" => %w[no_current_cohorts other],
          "other_reason" => "Custom reason"
        },
        effective_on: effective_on
      )
    end

    context "when a provider change is present" do
      it "loads the change into the state store" do
        wizard.set_state_store(provider_change)

        expect(state_store.read).to include(
          new_status: "inactive",
          reasons: %w[no_current_cohorts other],
          other_reason: "Custom reason",
          effective_on: Date.new(2027, 1, 15)
        )
      end
    end

    context "when no provider change is present" do
      it "does not change the state store" do
        state_store.write(
          new_status: "active",
          effective_on: Date.new(2027, 2, 1)
        )

        wizard.set_state_store(nil)

        expect(state_store.read).to include(
          new_status: "active",
          effective_on: Date.new(2027, 2, 1)
        )
      end
    end
  end

  describe "#provider_change_attributes" do
    before do
      state_store.write(
        new_status: "inactive",
        reasons: %w[no_current_cohorts financial_viability other],
        other_reason: "Custom reason",
        effective_on: effective_on
      )
    end

    it "returns the attributes for the provider change" do
      expect(wizard.provider_change_attributes).to eq(
        attribute_name: "status",
        effective_on: effective_on,
        value: {
          "status" => "inactive",
          "reason_ids" => %w[no_current_cohorts financial_viability other],
          "other_reason" => "Custom reason"
        }
      )
    end

    context "when the new status does not need reasons" do
      before do
        state_store.write(new_status: "active")
      end

      it "stores only the status" do
        state = wizard.provider_change_attributes

        expect(state[:value]).to eq("status" => "active")
      end
    end

    context "when Other is not among the reasons but other_reason lingers in the store" do
      # A previous Other selection can leave text behind (e.g. after going
      # back from a later step); the payload must follow the selection, not
      # the stale text.
      before do
        state_store.write(
          new_status: "inactive",
          reasons: %w[no_current_cohorts],
          other_reason: "Stale custom reason",
          effective_on: effective_on
        )
      end

      it "omits other_reason from the payload" do
        expect(wizard.provider_change_attributes[:value]).to eq(
          "status" => "inactive",
          "reason_ids" => %w[no_current_cohorts]
        )
      end
    end
  end
end
