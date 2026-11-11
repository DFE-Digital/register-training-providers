require "rails_helper"

RSpec.describe Partnerships::AddWizard do
  include Rails.application.routes.url_helpers

  subject(:wizard) do
    described_class.new(
      provider:,
      current_step:,
      current_step_params:,
      state_store:
    )
  end

  let(:provider) { create(:provider, :accredited) }
  let(:current_step) { :find_partner }
  let(:current_step_params) { {} }
  let(:repository) { DfE::Wizard::Repository::InMemory.new }
  let(:state_store) { Partnerships::StateStores::AddStore.new(repository:) }

  describe "step graph" do
    it { is_expected.to have_root_step(:find_partner) }

    it do
      expect(wizard)
        .to have_next_step(:dates)
        .from(:find_partner)
    end

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
    it "routes find_partner" do
      expect(wizard).to resolve_step(:find_partner).to(
        provider_new_partnership_step_path(provider, step: "find-partner")
      )
    end

    it "routes dates" do
      expect(wizard).to resolve_step(:dates).to(
        provider_new_partnership_step_path(provider, step: "dates")
      )
    end

    it "routes academic_years" do
      expect(wizard).to resolve_step(:academic_years).to(
        provider_new_partnership_step_path(provider, step: "academic-years")
      )
    end

    it "routes check_your_answers" do
      expect(wizard).to resolve_step(:check_your_answers).to(
        provider_new_partnership_step_path(provider, step: "check-your-answers")
      )
    end
  end

  describe "#check_your_answers?" do
    let(:current_step) { :check_your_answers }

    it { is_expected.to be_check_your_answers }
  end

  describe "#partnership_form" do
    let(:partner) { create(:provider, :hei_without_accreditation) }

    before do
      state_store.write(
        partner_id: partner.id,
        start_date_day: 1,
        start_date_month: 8,
        start_date_year: 2024,
        end_date_day: 31,
        end_date_month: 7,
        end_date_year: 2026,
        academic_year_ids: [123]
      )
    end

    it "maps the partner onto the training partner when the provider is accredited" do
      form = wizard.partnership_form

      expect(form.provider_id).to eq(partner.id)
      expect(form.accredited_provider_id).to eq(provider.id)
      expect(form.start_date).to eq(Date.new(2024, 8, 1))
      expect(form.end_date).to eq(Date.new(2026, 7, 31))
      expect(form.academic_year_ids).to eq([123])
    end

    context "when the provider is not accredited" do
      let(:provider) { create(:provider, :hei_without_accreditation) }

      it "maps the partner onto the accredited provider" do
        form = wizard.partnership_form

        expect(form.accredited_provider_id).to eq(partner.id)
        expect(form.provider_id).to eq(provider.id)
      end
    end
  end
end
