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

  def replacement_partnership
    Partnership.kept
      .where(accredited_provider: provider, provider: partner)
      .where.not(id: partnership.id)
      .first
  end

  describe "GET the first step" do
    it "seeds the journey from the partnership" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Select partnership types")
      expect(response.body).to include(provider.operating_name)
    end

    context "when the accredited provider is archived" do
      before { provider.update!(archived_at: Time.zone.now) }

      it "forbids the edit journey even though the training partner is active" do
        get root_path

        expect(response).to have_http_status(:forbidden)
      end
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

    it "does not end the partnership when the replacement cannot be saved" do
      partnership.partnership_types.create!(partnership_type: PartnershipTypeEnum::TRAINING_AND_DELIVERY)

      get root_path
      submit_start_date
      submit_end_date_question
      submit_academic_years
      patch step_path("types"),
            params: { types: { partnership_types: [PartnershipTypeEnum::TRAINING_AND_DELIVERY] } }

      allow_any_instance_of(Partnership).to receive(:save).and_wrap_original do |method, *args|
        method.receiver == partnership ? method.call(*args) : false
      end

      patch step_path("check-your-answers")

      expect(response).to have_http_status(:unprocessable_content)
      expect(partnership.reload.duration.end).to eq(Float::INFINITY)
      expect(partnership.partnership_types.kept.map(&:partnership_type))
        .to match_array([PartnershipTypeEnum::RECRUITMENT, PartnershipTypeEnum::TRAINING_AND_DELIVERY])
      expect(replacement_partnership).to be_nil
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

  describe "changing the partnership types" do
    before do
      partnership.partnership_types.create!(partnership_type: PartnershipTypeEnum::TRAINING_AND_DELIVERY)
    end

    def complete_journey(types, has_end_date: false, end_year: nil, start_year: "2024",
                         start_month: "9", start_day: "1", academic_year_ids: nil)
      get root_path
      submit_start_date(day: start_day, month: start_month, year: start_year)
      submit_end_date_question(has_end_date:)
      submit_end_date(year: end_year) if has_end_date
      submit_academic_years(academic_year_ids || [academic_year.id])
      patch step_path("types"), params: { types: { partnership_types: types } }
      patch step_path("check-your-answers")
    end

    it "ends the current partnership and starts a replacement when a type is removed" do
      complete_journey([PartnershipTypeEnum::RECRUITMENT])

      expect(response).to redirect_to(provider_partnerships_path(provider))

      expect(partnership.reload.duration.end).to eq(Time.zone.today)
      expect(partnership.partnership_types.kept.map(&:partnership_type))
        .to match_array([PartnershipTypeEnum::RECRUITMENT, PartnershipTypeEnum::TRAINING_AND_DELIVERY])

      replacement = replacement_partnership
      expect(replacement.duration.begin).to eq(Time.zone.today)
      expect(replacement.partnership_types.kept.map(&:partnership_type))
        .to match_array([PartnershipTypeEnum::RECRUITMENT])
      expect(replacement.academic_years).to include(academic_year)
    end

    it "starts a replacement when a type is added" do
      complete_journey([PartnershipTypeEnum::RECRUITMENT,
                        PartnershipTypeEnum::TRAINING_AND_DELIVERY,
                        PartnershipTypeEnum::STUDENT_FEE_MANAGEMENT])

      expect(partnership.reload.duration.end).to eq(Time.zone.today)
      expect(replacement_partnership.partnership_types.kept.map(&:partnership_type))
        .to match_array([PartnershipTypeEnum::RECRUITMENT,
                         PartnershipTypeEnum::TRAINING_AND_DELIVERY,
                         PartnershipTypeEnum::STUDENT_FEE_MANAGEMENT])
    end

    it "carries the end date to the replacement" do
      complete_journey([PartnershipTypeEnum::RECRUITMENT], has_end_date: true, end_year: "2028")

      expect(partnership.reload.duration.end).to eq(Time.zone.today)
      expect(replacement_partnership.duration.end).to eq(Date.new(2028, 7, 31))
    end

    it "refuses an end date before today instead of building an impossible replacement" do
      past_year = create(:academic_year, academic_year: 2024)

      complete_journey([PartnershipTypeEnum::RECRUITMENT], has_end_date: true, end_year: "2025",
                                                           academic_year_ids: [past_year.id])

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("End date must be after #{Time.zone.today.to_fs(:govuk)}")
      expect(partnership.reload.duration.end).not_to be_a(Date)
      expect(replacement_partnership).to be_nil
    end

    it "refuses a start date that leaves nothing to end on" do
      complete_journey([PartnershipTypeEnum::RECRUITMENT],
                       start_year: Time.zone.today.year.to_s,
                       start_month: Time.zone.today.month.to_s,
                       start_day: Time.zone.today.day.to_s)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Start date must be before #{Time.zone.today.to_fs(:govuk)}")
      expect(partnership.reload.duration.begin).to eq(Date.new(Time.zone.today.year, 1, 1))
      expect(partnership.reload.duration.end).not_to be_a(Date)
      expect(replacement_partnership).to be_nil
    end

    it "refuses an academic year that overlaps neither the replacement nor the partnership" do
      past_year = create(:academic_year, academic_year: 2024)
      partnership.update!(duration: Date.new(2024, 9, 1)..)

      complete_journey([PartnershipTypeEnum::RECRUITMENT], academic_year_ids: [past_year.id])

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Select an academic year available for these partnership dates")
      expect(replacement_partnership).to be_nil
    end

    it "reports the failure instead of calling another same-pair partnership the replacement" do
      create(:partnership,
             accredited_provider: provider,
             provider: partner,
             duration: Time.zone.today..,
             partnership_type: PartnershipTypeEnum::ACADEMIC_AWARD_MAKING)

      allow_any_instance_of(Partnership).to receive(:save).and_wrap_original do |method, *args|
        method.receiver == partnership ? method.call(*args) : false
      end

      complete_journey([PartnershipTypeEnum::STUDENT_FEE_MANAGEMENT])

      expect(response).to have_http_status(:unprocessable_content)
      expect(partnership.reload.duration.end).not_to be_a(Date)
      expect(Partnership.kept.where.not(id: partnership.id).count).to eq(1)
    end

    it "keeps the start date submitted with the type change on the record that is ended" do
      complete_journey([PartnershipTypeEnum::RECRUITMENT], start_year: "2025")

      expect(response).to redirect_to(provider_partnerships_path(provider))
      expect(partnership.reload.duration.begin).to eq(Date.new(2025, 9, 1))
      expect(partnership.reload.duration.end).to eq(Time.zone.today)
    end

    it "updates in place when the types are unchanged" do
      complete_journey([PartnershipTypeEnum::RECRUITMENT, PartnershipTypeEnum::TRAINING_AND_DELIVERY])

      expect(partnership.reload.duration.end).to eq(Float::INFINITY)
      expect(replacement_partnership).to be_nil
    end

    it "keeps an existing academic year that ended before the revision" do
      past_year = create(:academic_year, academic_year: 2025)
      partnership.update!(academic_years: [past_year])

      complete_journey([PartnershipTypeEnum::RECRUITMENT], academic_year_ids: [past_year.id])

      expect(response).to redirect_to(provider_partnerships_path(provider))
      expect(replacement_partnership.academic_years).to include(past_year)
    end

    it "rejects removing every type" do
      get root_path
      submit_start_date
      submit_end_date_question
      submit_academic_years

      patch step_path("types"), params: { types: { partnership_types: [] } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Select at least one partnership type")
      expect(replacement_partnership).to be_nil
    end

    it "does not revise when a removed type is added back in the same journey" do
      get root_path
      submit_start_date
      submit_end_date_question
      submit_academic_years

      patch step_path("types"),
            params: { types: { partnership_types: [PartnershipTypeEnum::RECRUITMENT] } }
      expect(response).to redirect_to(
        provider_partnership_type_change_path(partnership, provider_id: provider.id)
      )

      patch step_path("types"),
            params: { types: { partnership_types: [PartnershipTypeEnum::RECRUITMENT,
                                                   PartnershipTypeEnum::TRAINING_AND_DELIVERY] } }
      expect(response).to redirect_to(step_path("start-date"))

      patch step_path("check-your-answers")

      expect(partnership.reload.duration.end).to eq(Float::INFINITY)
      expect(replacement_partnership).to be_nil
    end

    it "adds an end date without versioning the partnership" do
      get root_path
      submit_start_date(day: "1", month: "1", year: "2026")
      submit_end_date_question(has_end_date: true)
      submit_end_date(year: "2028")
      submit_academic_years
      patch step_path("check-your-answers")

      expect(response).to redirect_to(provider_partnerships_path(provider))
      expect(partnership.reload.duration.end).to eq(Date.new(2028, 7, 31))
      expect(replacement_partnership).to be_nil
    end

    describe "a partnership that starts today" do
      let!(:partnership) do
        create(:partnership, accredited_provider: provider, provider: partner,
                             duration: Time.zone.today..)
      end

      it "changes the types in place, because there is no history to end" do
        get root_path
        submit_start_date(today: true)
        submit_end_date_question
        submit_academic_years
        patch step_path("types"),
              params: { types: { partnership_types: [PartnershipTypeEnum::RECRUITMENT] } }

        expect(response).to redirect_to(step_path("start-date"))

        patch step_path("check-your-answers")

        expect(response).to redirect_to(provider_partnerships_path(provider))
        expect(partnership.reload.duration.end).to eq(Float::INFINITY)
        expect(partnership.partnership_types.kept.map(&:partnership_type))
          .to match_array([PartnershipTypeEnum::RECRUITMENT])
        expect(replacement_partnership).to be_nil
      end
    end

    describe "a scheduled partnership" do
      let!(:partnership) do
        create(:partnership, accredited_provider: provider, provider: partner,
                             duration: Date.new(2027, 9, 1)..)
      end
      let!(:future_year) { create(:academic_year, academic_year: 2027) }

      it "updates the types in place without a historic record" do
        get root_path
        submit_start_date(year: "2027")
        submit_end_date_question
        submit_academic_years([future_year.id])
        patch step_path("types"),
              params: { types: { partnership_types: [PartnershipTypeEnum::RECRUITMENT] } }

        expect(response).to redirect_to(step_path("start-date"))

        patch step_path("check-your-answers")

        expect(partnership.reload.duration.begin).to eq(Date.new(2027, 9, 1))
        expect(partnership.partnership_types.kept.map(&:partnership_type))
          .to match_array([PartnershipTypeEnum::RECRUITMENT])
        expect(replacement_partnership).to be_nil
      end
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

    it "offers to enter an end date when the partnership has none" do
      get step_path("check-your-answers")

      expect(response.body).to include("Enter end date")
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
    it "sends the user back through the steps rather than saving a stale academic-year selection" do
      get root_path
      submit_start_date
      submit_end_date_question
      submit_academic_years

      # Move the dates out from under the selection, the way the Change link on
      # check your answers does. The academic year no longer overlaps, so the
      # wizard walks the user back rather than letting the save through.
      submit_start_date(year: "2040", return_to_review: "true")

      expect(response).to redirect_to(step_path("end-date-question", return_to_review: "true"))

      patch step_path("check-your-answers")

      expect(response).to redirect_to(root_path)
      expect(partnership.reload.duration.begin).to eq(Date.new(2026, 1, 1))
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
