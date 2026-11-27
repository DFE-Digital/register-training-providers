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
    provider_edit_partnership_step_path(provider_id: provider.id, partnership_id: partnership.id, step: step, **)
  end

  def root_path
    provider_edit_partnership_step_path(provider_id: provider.id, partnership_id: partnership.id)
  end

  def submit_dates(day: "1", month: "9", year: "2024", **)
    patch step_path("dates", **), params: {
      dates: {
        "start_date(3i)" => day,
        "start_date(2i)" => month,
        "start_date(1i)" => year
      }
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
      expect(response.body).to include("Partnership dates")
      expect(response.body).to include(provider.operating_name)
    end

    it "pre-fills the partnership's current dates on the entry URL the Change link uses" do
      partnership.update!(duration: Date.new(2024, 9, 1)...Date.new(2026, 7, 31))

      get step_path("dates")

      document = response.parsed_body
      expect(document.at_css("#dates_start_date_3i")["value"]).to eq("1")
      expect(document.at_css("#dates_start_date_2i")["value"]).to eq("9")
      expect(document.at_css("#dates_start_date_1i")["value"]).to eq("2024")
      expect(document.at_css("#dates_end_date_3i")["value"]).to eq("31")
      expect(document.at_css("#dates_end_date_2i")["value"]).to eq("7")
      expect(document.at_css("#dates_end_date_1i")["value"]).to eq("2026")
    end

    it "pre-ticks the partnership's current academic years" do
      overlapping_year = create(:academic_year, academic_year: 2024)
      partnership.academic_years << overlapping_year
      partnership.update!(duration: Date.new(2024, 9, 1)...Date.new(2026, 7, 31))

      get step_path("dates")
      submit_dates

      get step_path("academic-years")

      document = response.parsed_body
      checkbox = document.at_css("input[type='checkbox'][value='#{overlapping_year.id}']")
      expect(checkbox["checked"]).to eq("checked")
    end

    it "returns the user to the partnerships list when the path is invalid" do
      get step_path("check-your-answers")

      expect(response).to redirect_to(root_path)
    end
  end

  describe "PATCH the dates step" do
    before { get root_path }

    it "moves on to the academic year step" do
      submit_dates

      expect(response).to redirect_to(step_path("academic-years"))
    end
  end

  describe "PATCH the academic years step" do
    before do
      get root_path
      submit_dates
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

    it "keeps the end date when the pre-filled dates are submitted unchanged" do
      partnership.update!(duration: Date.new(2024, 9, 1)...Date.new(2026, 7, 31))

      get step_path("dates")
      submit_dates(end_day: "31", end_month: "7", end_year: "2026")
      submit_academic_years([overlapping_year.id])
      patch step_path("check-your-answers")

      expect(partnership.reload.duration.end).to eq(Date.new(2026, 7, 31))
    end
  end

  describe "the complete edit journey" do
    before do
      get root_path
      submit_dates
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
      expect(flash[:success]).to eq(I18n.t("flash_message.success.check.partnership.update"))

      partnership.reload
      expect(partnership.duration.begin).to eq(Date.new(2024, 9, 1))
      expect(partnership.academic_years).to include(academic_year)
      expect(partnership.provider).to eq(partner)
      expect(partnership.accredited_provider).to eq(provider)
    end
  end

  describe "changing a single answer from check your answers" do
    before do
      get root_path
      submit_dates
      submit_academic_years
    end

    it "re-picks the academic years when the dates change" do
      submit_dates(day: "2", return_to_review: "true")

      expect(response).to redirect_to(step_path("academic-years", return_to_review: "true"))
    end

    it "returns to check your answers after the academic years step" do
      submit_academic_years([academic_year.id], return_to_review: "true")

      expect(response).to redirect_to(step_path("check-your-answers", return_to_review: "true"))
    end
  end
end
