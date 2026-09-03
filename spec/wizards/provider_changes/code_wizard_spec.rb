# spec/wizards/provider_changes/code_wizard_spec.rb

require "rails_helper"

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
end
