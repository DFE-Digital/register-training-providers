RSpec.describe ProviderChanges::LegalNameWizard do
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
  let(:current_step) { :effective_date }
  let(:current_step_params) { {} }
  let(:effective_on) { Date.new(2027, 1, 15) }

  let(:repository) { DfE::Wizard::Repository::InMemory.new }

  let(:state_store) do
    ProviderChanges::StateStores::LegalNameStore.new(repository:)
  end

  describe "step graph" do
    it { is_expected.to have_root_step(:effective_date) }

    it do
      expect(wizard)
        .to have_next_step(:new_legal_name)
        .from(:effective_date)
    end

    it do
      expect(wizard)
        .to have_next_step(:check_your_answers)
        .from(:new_legal_name)
    end

    it do
      expect(wizard)
        .to have_next_step(nil)
        .from(:check_your_answers)
    end
  end

  describe "routes" do
    it "routes effective_date" do
      expect(wizard).to resolve_step(:effective_date).to(
        provider_change_update_step_path(
          provider_id: provider.id,
          field: "legal_name",
          step: "effective-date"
        )
      )
    end

    it "routes new_legal_name" do
      expect(wizard).to resolve_step(:new_legal_name).to(
        provider_change_update_step_path(
          provider_id: provider.id,
          field: "legal_name",
          step: "new-legal-name"
        )
      )
    end

    it "routes check_your_answers" do
      expect(wizard).to resolve_step(:check_your_answers).to(
        provider_change_update_step_path(
          provider_id: provider.id,
          field: "legal_name",
          step: "check-your-answers"
        )
      )
    end
  end

  describe "review navigation" do
    before do
      state_store.write(
        effective_on: effective_on,
        legal_name: "New provider name"
      )
    end

    context "when returning to review" do
      let(:current_step_params) { { return_to_review: "new_legal_name" } }

      it "goes to check your answers" do
        expect(wizard.next_step).to eq(:check_your_answers)
      end
    end

    context "when returning from review" do
      let(:current_step) { :new_legal_name }
      let(:current_step_params) { { return_to_review: "new_legal_name" } }

      it "goes to check your answers" do
        expect(wizard.previous_step).to eq(:check_your_answers)
      end
    end
  end

  describe "check_your_answers?" do
    context "when current_step is effective_date" do
      let(:current_step) { :effective_date }

      it "returns false" do
        expect(wizard.check_your_answers?).to be(false)
      end
    end

    context "when current_step is new_legal_name" do
      let(:current_step) { :new_legal_name }

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
        attribute_name: "legal_name",
        value: "New provider name",
        effective_on: Date.new(2027, 1, 15)
      )
    end

    context "when a provider change is present" do
      it "loads the change into the state store" do
        wizard.set_state_store(provider_change)

        expect(state_store.read).to include(
          legal_name: "New provider name",
          effective_on: Date.new(2027, 1, 15)
        )
      end

      it "materialises the date components when the date step is hydrated" do
        wizard.set_state_store(provider_change)

        step = wizard.step(:effective_date)

        expect(step.effective_on_day).to eq(15)
        expect(step.effective_on_month).to eq(1)
        expect(step.effective_on_year).to eq(2027)
      end
    end

    context "when no provider change is present" do
      it "does not change the state store" do
        state_store.write(
          legal_name: "Another provider name",
          effective_on: Date.new(2027, 2, 1)
        )

        wizard.set_state_store(nil)

        expect(state_store.read).to include(
          legal_name: "Another provider name",
          effective_on: Date.new(2027, 2, 1)
        )
      end
    end
  end

  describe "#provider_change_attributes" do
    before do
      state_store.write(
        effective_on: Date.new(2027, 1, 15),
        legal_name: "New provider name"
      )
    end

    it "returns the attributes for the provider change" do
      expect(wizard.provider_change_attributes).to eq(
        attribute_name: "legal_name",
        effective_on: Date.new(2027, 1, 15),
        value: "New provider name"
      )
    end
  end
end
