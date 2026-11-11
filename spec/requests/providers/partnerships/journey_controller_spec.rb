require "rails_helper"

RSpec.describe "Provider partnership add journey", type: :request do
  include DfESignInUserHelper

  let(:user) { create(:user) }

  before do
    user_exists_in_dfe_sign_in(user:)
    get "/auth/dfe/callback"
  end

  after { OmniAuth.config.mock_auth.clear }

  let(:accredited_provider) { create(:provider, :accredited) }
  let!(:partner) { create(:provider, :hei_without_accreditation, operating_name: "Partner College") }
  let!(:academic_year) { create(:academic_year) }

  def step_path(step, **)
    provider_partnership_step_path(accredited_provider, step:, **)
  end

  def choose_partner(partner_id = partner.id, **)
    post step_path("find-partner", **), params: { find_partner: { partner_id: } }
  end

  def submit_types(types = ["recruitment"], **)
    post step_path("types", **), params: { types: { partnership_types: types } }
  end

  def submit_dates(day: "1", month: "8", year: "2024", **)
    post step_path("dates", **), params: {
      dates: {
        "start_date(3i)" => day,
        "start_date(2i)" => month,
        "start_date(1i)" => year
      }
    }
  end

  def submit_academic_years(ids = [academic_year.id])
    post step_path("academic-years"), params: { academic_years: { academic_year_ids: ids } }
  end

  describe "GET the find step" do
    it "offers unaccredited providers as eligible training partners" do
      get provider_partnership_step_path(accredited_provider)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Partner College")
      expect(response.body).to include("Enter training partner name")
    end

    it "offers accredited providers when the provider is not accredited" do
      unaccredited_provider = create(:provider, :hei_without_accreditation, operating_name: "Training Provider")
      create(:provider, :hei, operating_name: "Accredited University")

      get provider_partnership_step_path(unaccredited_provider)

      expect(response.body).to include("Accredited University")
      expect(response.body).to include("Enter accredited provider name")
    end

    it "uses the provider name in the caption" do
      get provider_partnership_step_path(accredited_provider)

      expect(response.body).to include(accredited_provider.operating_name)
    end
  end

  describe "POST the find step" do
    it "rejects a missing partner" do
      post step_path("find-partner"), params: { find_partner: { partner_id: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Enter training partner name")
    end

    it "rejects an unknown partner" do
      post step_path("find-partner"), params: { find_partner: { partner_id: SecureRandom.uuid } }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects a partner with the wrong provider type" do
      other_accredited_provider = create(:provider, :accredited)

      post step_path("find-partner"), params: { find_partner: { partner_id: other_accredited_provider.id } }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects an archived partner" do
      partner.update!(archived_at: Time.zone.now)

      choose_partner

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "moves on to the types step" do      choose_partner

      expect(response).to redirect_to(step_path("types"))
    end

    it "returns to check your answers when the partner is changed from there" do
      choose_partner
      submit_types
      submit_dates
      submit_academic_years
      choose_partner(partner.id, return_to_review: "true")

      expect(response).to redirect_to(step_path("check-your-answers", return_to_review: "true"))
    end
  end

  describe "POST the types step" do
    before { choose_partner }

    it "requires at least one type" do
      submit_types([""])

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Select at least one partnership type")
    end

    it "moves on to the dates step" do
      submit_types

      expect(response).to redirect_to(step_path("dates"))
    end

    it "returns to check your answers when types change from there" do
      choose_partner
      submit_types
      submit_dates
      submit_academic_years

      submit_types([PartnershipTypeEnum::TRAINING_AND_DELIVERY], return_to_review: "true")

      expect(response).to redirect_to(step_path("check-your-answers", return_to_review: "true"))
    end

    it "explains when no partnership type is available" do
      create(:partnership, accredited_provider: accredited_provider, provider: partner,
                           partnership_type: PartnershipTypeEnum::RECRUITMENT)
      create(:partnership, accredited_provider: accredited_provider, provider: partner,
                           partnership_type: PartnershipTypeEnum::TRAINING_AND_DELIVERY)
      create(:partnership, accredited_provider: accredited_provider, provider: partner,
                           partnership_type: PartnershipTypeEnum::STUDENT_FEE_MANAGEMENT)
      create(:partnership, accredited_provider: accredited_provider, provider: partner,
                           partnership_type: PartnershipTypeEnum::ACADEMIC_AWARD_MAKING)

      get step_path("types")

      expect(response.body).to include("cannot be added")
      expect(Nokogiri::HTML(response.body).css("input[type='checkbox']")).to be_empty
    end

    it "rejects a type that is already used with this partner" do
      create(:partnership, accredited_provider: accredited_provider, provider: partner)

      submit_types([PartnershipTypeEnum::RECRUITMENT])

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Select a valid partnership type")
    end

    it "hides types already used with this partner" do
      create(:partnership, accredited_provider: accredited_provider, provider: partner)

      get step_path("types")

      document = Nokogiri::HTML(response.body)
      expect(document.css("input[name='types[partnership_types][]']").pluck("value"))
        .not_to include(PartnershipTypeEnum::RECRUITMENT)
      expect(document.css("ul.govuk-list--bullet li").map(&:text)).to eq(["Recruitment"])
      expect(response.body).to include("Partnership types already used")
      expect(response.body).to include("already part of another current or scheduled partnership with this training partner:")
      expect(response.body).to include("Available partnership types")
    end

    it "does not offer placement when the training partner is not a school" do
      get step_path("types")

      expect(response.body).to include("Placement is not available")
      expect(response.body).to include("Available partnership types")
      expect(Nokogiri::HTML(response.body).css("input[name='types[partnership_types][]']").pluck("value"))
        .not_to include(PartnershipTypeEnum::PLACEMENT)
    end

    it "renders the supporting content inside the types fieldset" do
      get step_path("types")

      fieldset = Nokogiri::HTML(response.body).at_css("fieldset.govuk-fieldset")
      content = fieldset.inner_html

      expect(content.index("Select partnership types")).to be < content.index("All selected partnership types")
      expect(content.index("All selected partnership types")).to be < content.index("Placement is not available")
      expect(content.index("Placement is not available")).to be < content.index("Select all that apply")
      expect(fieldset.text).to include("Available partnership types")
    end

    it "offers placement when the training partner is a school" do
      school_partner = create(:provider, :school, operating_name: "Placement School")
      choose_partner(school_partner.id)

      get step_path("types")

      expect(Nokogiri::HTML(response.body).css("input[name='types[partnership_types][]']").pluck("value"))
        .to include(PartnershipTypeEnum::PLACEMENT)
      expect(response.body).not_to include("Placement is not available")
    end
  end

  describe "POST the dates step" do
    before do
      choose_partner
      submit_types
    end

    it "rejects a missing start date" do
      submit_dates(day: "", month: "", year: "")

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Enter date the partnership started")
    end

    it "moves on to the academic year step" do
      submit_dates

      expect(response).to redirect_to(step_path("academic-years"))
    end

    it "re-picks the academic years when the dates change from check your answers" do
      submit_dates(day: "2", return_to_review: "true")

      expect(response).to redirect_to(step_path("academic-years", return_to_review: "true"))
    end
  end

  describe "POST the academic years step" do
    before do
      choose_partner
      submit_types
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

  describe "the complete journey" do
    before do
      choose_partner
      submit_types
      submit_dates
      submit_academic_years
    end

    it "shows the answers before saving" do
      get step_path("check-your-answers")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Check your answers")
      expect(response.body).to include(partner.operating_name)
      expect(response.body).to include(accredited_provider.operating_name)
      expect(response.body).to include("Partnership types")
      expect(response.body).to include("Recruitment")
    end

    it "creates the partnership with a recruitment type" do
      expect { post step_path("check-your-answers") }
        .to change(Partnership, :count).by(1)
        .and change(PartnershipType, :count).by(1)

      expect(response).to redirect_to(provider_partnerships_path(accredited_provider))
      expect(flash[:success]).to eq(I18n.t("flash_message.success.check.partnership.add"))

      partnership = Partnership.last
      expect(partnership.provider).to eq(partner)
      expect(partnership.accredited_provider).to eq(accredited_provider)
      expect(partnership.partnership_types.map(&:partnership_type))
        .to eq([PartnershipTypeEnum::RECRUITMENT])
      expect(partnership.academic_years).to include(academic_year)
      expect(partnership.duration.begin).to eq(Date.new(2024, 8, 1))
    end

    it "clears the journey state after saving" do
      post step_path("check-your-answers")

      get step_path("check-your-answers")

      expect(response).to redirect_to(step_path("find-partner"))
    end

    it "sends the user back to the types step if a selected type becomes unavailable" do
      create(:partnership, accredited_provider: accredited_provider, provider: partner)

      expect { post step_path("check-your-answers") }.not_to change(Partnership, :count)

      expect(response).to redirect_to(step_path("types"))
      expect(flash[:alert]).to include("no longer available")
    end
  end

  describe "when the journey has not been started" do
    it "returns the user to the first step from check your answers" do
      get step_path("check-your-answers")

      expect(response).to redirect_to(step_path("find-partner"))
    end
  end

  describe "restarting the journey" do
    before do
      choose_partner
      submit_types
      submit_dates
      submit_academic_years
    end

    it "discards the answers from an abandoned journey" do
      get provider_partnership_step_path(accredited_provider)

      get step_path("check-your-answers")

      expect(response).to redirect_to(step_path("find-partner"))
    end
  end
end
