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
  let(:current_step) { :start_date }
  let(:current_step_params) { {} }
  let(:repository) { DfE::Wizard::Repository::InMemory.new }
  let(:state_store) { Partnerships::StateStores::PartnershipStore.new(repository:) }

  describe "step graph" do
    it { is_expected.to have_root_step(:types) }

    it do
      expect(wizard)
        .to have_next_step(:start_date)
        .from(:types)
    end

    it do
      expect(wizard)
        .to have_next_step(:end_date_question)
        .from(:start_date)
    end

    it do
      expect(wizard)
        .to have_next_step(:academic_years)
        .from(:end_date)
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
    it "routes types" do
      expect(wizard).to resolve_step(:types).to(
        provider_partnership_edit_step_path(provider, partnership, step: "types")
      )
    end

    it "routes start_date" do
      expect(wizard).to resolve_step(:start_date).to(
        provider_partnership_edit_step_path(provider, partnership, step: "start-date")
      )
    end

    it "routes end_date_question" do
      expect(wizard).to resolve_step(:end_date_question).to(
        provider_partnership_edit_step_path(provider, partnership, step: "end-date-question")
      )
    end

    it "routes end_date" do
      expect(wizard).to resolve_step(:end_date).to(
        provider_partnership_edit_step_path(provider, partnership, step: "end-date")
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
      expect(state[:has_end_date]).to eq("true")
      expect(state[:start_today]).to eq("false")
      expect(state[:start_date]).to eq(Date.new(2024, 9, 1))
      expect(state[:end_date]).to eq(Date.new(2026, 7, 31))
      expect(state[:start_date_day]).to eq(1)
      expect(state[:start_date_month]).to eq(9)
      expect(state[:start_date_year]).to eq(2024)
      expect(state[:end_date_day]).to eq(31)
      expect(state[:end_date_month]).to eq(7)
      expect(state[:end_date_year]).to eq(2026)
      expect(state[:academic_year_ids]).to eq([academic_year.id])
      expect(state[:partnership_types]).to eq([PartnershipTypeEnum::RECRUITMENT])
    end

    it "leaves the end date blank for an open ended partnership" do
      wizard.seed_from_partnership

      state = state_store.read.with_indifferent_access
      expect(state[:end_date]).to be_nil
      expect(state[:end_date_day]).to be_nil
      expect(state[:end_date_year]).to be_nil
    end
  end

  describe "type availability" do
    it "keeps the partnership's own types selectable" do
      expect(wizard.available_partnership_types).to include(PartnershipTypeEnum::RECRUITMENT)
    end

    it "excludes a type used by another current partnership for the pair" do
      create(:partnership,
             accredited_provider: provider,
             provider: partner,
             partnership_type: PartnershipTypeEnum::TRAINING_AND_DELIVERY)

      expect(wizard.available_partnership_types).not_to include(PartnershipTypeEnum::TRAINING_AND_DELIVERY)
    end

    it "does not offer placement when the training partner is not a school" do
      expect(wizard.available_partnership_types).not_to include(PartnershipTypeEnum::PLACEMENT)
    end

    it "offers placement when the training partner is a school" do
      partnership.update!(provider: create(:provider, :school))

      expect(wizard.available_partnership_types).to include(PartnershipTypeEnum::PLACEMENT)
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
