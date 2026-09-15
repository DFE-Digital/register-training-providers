RSpec.describe ProviderChanges::CodeWizard do
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
  let(:current_step) { :effective_academic_year }
  let(:current_step_params) { {} }

  let(:repository) { DfE::Wizard::Repository::InMemory.new }

  let(:state_store) do
    ProviderChanges::StateStores::CodeStore.new(repository:)
  end

  describe "step graph" do
    it { is_expected.to have_root_step(:effective_academic_year) }

    it do
      expect(wizard)
        .to have_next_step(:new_code)
        .from(:effective_academic_year)
    end

    it do
      expect(wizard)
        .to have_next_step(:check_your_answers)
        .from(:new_code)
    end

    it do
      expect(wizard)
        .to have_next_step(nil)
        .from(:check_your_answers)
    end
  end

  describe "routes" do
    it "routes effective_academic_year" do
      expect(wizard).to resolve_step(:effective_academic_year).to(
        provider_change_update_step_path(
          provider_id: provider.id,
          field: "code",
          step: "effective-academic-year"
        )
      )
    end

    it "routes new_code" do
      expect(wizard).to resolve_step(:new_code).to(
        provider_change_update_step_path(
          provider_id: provider.id,
          field: "code",
          step: "new-code"
        )
      )
    end

    it "routes check_your_answers" do
      expect(wizard).to resolve_step(:check_your_answers).to(
        provider_change_update_step_path(
          provider_id: provider.id,
          field: "code",
          step: "check-your-answers"
        )
      )
    end
  end

  describe "review navigation" do
    before do
      state_store.write(
        effective_on: "1/1/2026",
        code: "ABC"
      )
    end

    context "when returning to review" do
      let(:current_step_params) { { return_to_review: "new_code" } }

      it "goes to check your answers" do
        expect(wizard.next_step).to eq(:check_your_answers)
      end
    end

    context "when returning from review" do
      let(:current_step) { :new_code }
      let(:current_step_params) { { return_to_review: "new_code" } }

      it "goes to check your answers" do
        expect(wizard.previous_step).to eq(:check_your_answers)
      end
    end
  end

  describe "check_your_answers?" do
    context "when current_step is effective_academic_year" do
      let(:current_step) { :effective_academic_year }

      it "returns false" do
        expect(wizard.check_your_answers?).to be(false)
      end
    end

    context "when current_step is new_code" do
      let(:current_step) { :new_code }

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
        attribute_name: "code",
        value: "ABC",
        effective_on: Date.new(2026, 9, 1)
      )
    end

    context "when a provider change is present" do
      it "loads the change into the state store" do
        wizard.set_state_store(provider_change)

        expect(state_store.read).to include(
          code: "ABC",
          effective_on: Date.new(2026, 9, 1)
        )
      end
    end

    context "when no provider change is present" do
      it "does not change the state store" do
        state_store.write(
          code: "XYZ",
          effective_on: Date.new(2026, 10, 1)
        )

        wizard.set_state_store(nil)

        expect(state_store.read).to include(
          code: "XYZ",
          effective_on: Date.new(2026, 10, 1)
        )
      end
    end
  end

  describe "#provider_change_attributes" do
    before do
      state_store.write(
        effective_on: Date.new(2026, 9, 1),
        code: "ABC"
      )
    end

    it "returns the attributes for the provider change" do
      expect(wizard.provider_change_attributes).to eq(
        attribute_name: "code",
        effective_on: Date.new(2026, 9, 1),
        value: "ABC"
      )
    end
  end
end
