require "rails_helper"

RSpec.describe Partnerships::EditWizard do
  include Rails.application.routes.url_helpers

  subject(:wizard) do
    described_class.new(
      provider:,
      partnership:,
      current_step:,
      current_step_params:,
      state_store:
    )
  end

  let(:provider) { create(:provider, :accredited) }
  let(:partner) { create(:provider, :hei_without_accreditation) }
  let(:partnership) { create(:partnership, accredited_provider: provider, provider: partner) }
  let(:current_step) { :dates }
  let(:current_step_params) { {} }
  let(:repository) { DfE::Wizard::Repository::InMemory.new }
  let(:state_store) { Partnerships::StateStores::PartnershipStore.new(repository:) }

  describe "step graph" do
    it { is_expected.to have_root_step(:dates) }

    it do
      expect(wizard)
        .to have_next_step(:academic_years)
        .from(:dates)
    end

    it do
      expect(wizard)
        .to have_next_step(:check_your_answers)
        .from(:academic_years)
    end

    it do
      expect(wizard)
        .to have_next_step(nil)
        .from(:check_your_answers)
    end
  end

  describe "routes" do
    it "routes dates" do
      expect(wizard).to resolve_step(:dates).to(
        provider_partnership_edit_step_path(provider, partnership, step: "dates")
      )
    end

    it "routes academic_years" do
      expect(wizard).to resolve_step(:academic_years).to(
        provider_partnership_edit_step_path(provider, partnership, step: "academic-years")
      )
    end

    it "routes check_your_answers" do
      expect(wizard).to resolve_step(:check_your_answers).to(
        provider_partnership_edit_step_path(provider, partnership, step: "check-your-answers")
      )
    end
  end

  describe "#seed_from_partnership" do
    it "seeds the journey from the partnership" do
      partnership.update!(duration: Date.new(2024, 9, 1)...Date.new(2026, 7, 31))
      academic_year = create(:academic_year)
      partnership.academic_years << academic_year

      wizard.seed_from_partnership

      state = state_store.read.with_indifferent_access
      expect(state[:start_date]).to eq(Date.new(2024, 9, 1))
      expect(state[:end_date]).to eq(Date.new(2026, 7, 31))
      expect(state[:start_date_day]).to eq(1)
      expect(state[:start_date_month]).to eq(9)
      expect(state[:start_date_year]).to eq(2024)
      expect(state[:end_date_day]).to eq(31)
      expect(state[:end_date_month]).to eq(7)
      expect(state[:end_date_year]).to eq(2026)
      expect(state[:academic_year_ids]).to eq([academic_year.id])
    end

    it "leaves the end date blank for an open ended partnership" do
      wizard.seed_from_partnership

      state = state_store.read.with_indifferent_access
      expect(state[:end_date]).to be_nil
      expect(state[:end_date_day]).to be_nil
      expect(state[:end_date_year]).to be_nil
    end
  end

  describe "#partnership_form" do
    it "keeps the partnership's own partners" do
      form = wizard.partnership_form

      expect(form.accredited_provider_id).to eq(provider.id)
      expect(form.provider_id).to eq(partner.id)
    end
  end
end
