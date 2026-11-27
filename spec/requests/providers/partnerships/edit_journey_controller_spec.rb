require "rails_helper"

RSpec.describe "Provider partnership edit journey", type: :request do
  include DfESignInUserHelper

  let(:user) { create(:user) }

  before do
    user_exists_in_dfe_sign_in(user:)
    get "/auth/dfe/callback"
  end

  after { OmniAuth.config.mock_auth.clear }

  let(:provider) { create(:provider, :accredited) }
  let(:partner) { create(:provider, :hei_without_accreditation, operating_name: "Partner College") }
  let!(:academic_year) { create(:academic_year) }
  let!(:partnership) { create(:partnership, accredited_provider: provider, provider: partner) }

  def step_path(step, **)
    provider_partnership_edit_step_path(provider_id: provider.id, partnership_id: partnership.id, step: step, **)
  end

  def root_path
    provider_partnership_edit_step_path(provider_id: provider.id, partnership_id: partnership.id)
  end

  def submit_start_date(day: "1", month: "9", year: "2024", today: false, **)
    attributes = { start_today: today ? "true" : "false" }

    unless today
      attributes["start_date(3i)"] = day
      attributes["start_date(2i)"] = month
      attributes["start_date(1i)"] = year
    end

    patch step_path("start-date", **), params: { start_date: attributes }
  end

  def submit_end_date_question(has_end_date: false, **)
    patch step_path("end-date-question", **),
          params: { end_date_question: { has_end_date: has_end_date ? "true" : "false" } }
  end

  def submit_end_date(day: "31", month: "7", year: "2026", **)
    patch step_path("end-date", **), params: {
      end_date: { "end_date(3i)" => day, "end_date(2i)" => month, "end_date(1i)" => year }
    }
  end

  def submit_academic_years(ids = [academic_year.id], **)
    patch step_path("academic-years", **),
          params: { academic_years: { academic_year_ids: ids } }
  end

  describe "GET the first step" do
    it "seeds the journey from the partnership" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Select partnership types")
      expect(response.body).to include(provider.operating_name)
    end

    it "pre-fills the partnership's current start date on the entry URL the Change link uses" do
      partnership.update!(duration: Date.new(2024, 9, 1)...Date.new(2026, 7, 31))

      get step_path("start-date")

      document = response.parsed_body
      expect(document.at_css("input[name='start_date[start_today]'][value='false']")["checked"]).to eq("checked")
      expect(document.at_css("input[id$='start_date_3i']")["value"]).to eq("1")
      expect(document.at_css("input[id$='start_date_2i']")["value"]).to eq("9")
      expect(document.at_css("input[id$='start_date_1i']")["value"]).to eq("2024")
    end

    it "pre-ticks the partnership's current academic years" do
      overlapping_year = create(:academic_year, academic_year: 2024)
      partnership.academic_years << overlapping_year
      partnership.update!(duration: Date.new(2024, 9, 1)...Date.new(2026, 7, 31))

      get step_path("start-date")
      submit_start_date
      submit_end_date_question

      get step_path("academic-years")

      document = response.parsed_body
      checkbox = document.at_css("input[type='checkbox'][value='#{overlapping_year.id}']")
      expect(checkbox["checked"]).to eq("checked")
    end

    it "returns the user to the first step when the step is not reachable" do
      partnership.update!(duration: 1.month.ago..)

      get step_path("end-date")

      expect(response).to redirect_to(root_path)
    end

    it "seeds a deep link from the partnership" do
      get step_path("check-your-answers")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Check your answers")
      expect(response.body).to include(partner.operating_name)
    end
  end

  describe "PATCH the dates step" do
    before { get root_path }

    it "moves on to the academic year step" do
      submit_start_date
      submit_end_date_question

      expect(response).to redirect_to(step_path("academic-years"))
    end
  end

  describe "PATCH the academic years step" do
    before do
      get root_path
      submit_start_date
      submit_end_date_question
    end

    it "rejects an empty selection" do
      submit_academic_years([""])

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Select academic year")
    end

    it "moves on to check your answers" do
      submit_academic_years

      expect(response).to redirect_to(step_path("check-your-answers"))
    end
  end

  describe "an edit with an existing end date" do
    let!(:overlapping_year) { create(:academic_year, academic_year: 2024) }

    it "clears the end date when the user says there is none" do
      partnership.update!(duration: Date.new(2024, 9, 1)...Date.new(2026, 7, 31))

      get step_path("start-date")
      submit_start_date
      submit_end_date_question(has_end_date: false)
      submit_academic_years([overlapping_year.id])
      patch step_path("check-your-answers")

      expect(partnership.reload.duration.end).to eq(Float::INFINITY)
    end

    it "keeps the existing types when the save fails" do
      partnership.partnership_types.create!(partnership_type: PartnershipTypeEnum::TRAINING_AND_DELIVERY)

      get root_path
      submit_start_date
      submit_end_date_question
      submit_academic_years
      patch step_path("types"),
            params: { types: { partnership_types: [PartnershipTypeEnum::TRAINING_AND_DELIVERY] } }

      allow_any_instance_of(Partnership).to receive(:update).and_return(false)

      patch step_path("check-your-answers")

      expect(partnership.partnership_types.kept.map(&:partnership_type))
        .to match_array([PartnershipTypeEnum::RECRUITMENT, PartnershipTypeEnum::TRAINING_AND_DELIVERY])
    end

    it "keeps the end date when the pre-filled dates are submitted unchanged" do
      partnership.update!(duration: Date.new(2024, 9, 1)...Date.new(2026, 7, 31))

      get step_path("start-date")
      submit_start_date
      submit_end_date_question(has_end_date: true)
      submit_end_date
      submit_academic_years([overlapping_year.id])
      patch step_path("check-your-answers")

      expect(partnership.reload.duration.end).to eq(Date.new(2026, 7, 31))
    end
  end

  describe "the complete edit journey" do
    before do
      get root_path
      submit_start_date
      submit_end_date_question
      submit_academic_years
    end

    it "shows the answers before saving" do
      get step_path("check-your-answers")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Check your answers")
      expect(response.body).to include(partner.operating_name)
    end

    it "updates the partnership" do
      patch step_path("check-your-answers")

      expect(response).to redirect_to(provider_partnerships_path(provider))
      expect(flash[:success]).to eq(I18n.t("flash_message.success.check.partnership.update", name: partner.operating_name))

      partnership.reload
      expect(partnership.duration.begin).to eq(Date.new(2024, 9, 1))
      expect(partnership.academic_years).to include(academic_year)
      expect(partnership.provider).to eq(partner)
      expect(partnership.accredited_provider).to eq(provider)
    end
  end

  describe "changing dates after selecting academic years" do
    it "rejects a stale academic-year selection on save" do
      get step_path("start-date")
      submit_start_date(year: "2040")
      submit_end_date_question

      patch step_path("check-your-answers")

      expect(response).to redirect_to(root_path)
      expect(partnership.reload.duration.begin).not_to eq(Date.new(2040, 9, 1))
    end
  end

  describe "changing a single answer from check your answers" do
    before do
      get root_path
      submit_start_date
      submit_end_date_question
      submit_academic_years
    end

    it "moves on to the end date question" do
      submit_start_date

      expect(response).to redirect_to(step_path("end-date-question"))
    end

    it "returns to check your answers after the academic years step" do
      submit_academic_years([academic_year.id], return_to_review: "true")

      expect(response).to redirect_to(step_path("check-your-answers", return_to_review: "true"))
    end
  end
end
