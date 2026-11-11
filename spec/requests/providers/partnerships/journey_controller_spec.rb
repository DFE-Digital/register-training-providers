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

  def step_path(step)
    provider_new_partnership_step_path(accredited_provider, step:)
  end

  def choose_partner(partner_id = partner.id)
    post step_path("find-partner"), params: { find_partner: { partner_id: } }
  end

  def submit_dates(day: "1", month: "8", year: "2024")
    post step_path("dates"), params: {
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
      get provider_new_partnership_step_path(accredited_provider)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Partner College")
      expect(response.body).to include("Enter training partner name")
    end

    it "offers accredited providers when the provider is not accredited" do
      unaccredited_provider = create(:provider, :hei_without_accreditation, operating_name: "Training Provider")
      create(:provider, :hei, operating_name: "Accredited University")

      get provider_new_partnership_step_path(unaccredited_provider)

      expect(response.body).to include("Accredited University")
      expect(response.body).to include("Enter accredited provider name")
    end

    it "uses the provider name in the caption" do
      get provider_new_partnership_step_path(accredited_provider)

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

    it "moves on to the dates step" do
      choose_partner

      expect(response).to redirect_to(step_path("dates"))
    end
  end

  describe "POST the dates step" do
    before { choose_partner }

    it "rejects a missing start date" do
      submit_dates(day: "", month: "", year: "")

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Enter date the partnership started")
    end

    it "moves on to the academic year step" do
      submit_dates

      expect(response).to redirect_to(step_path("academic-years"))
    end
  end

  describe "POST the academic years step" do
    before do
      choose_partner
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
      submit_dates
      submit_academic_years
    end

    it "shows the answers before saving" do
      get step_path("check-your-answers")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Check your answers")
      expect(response.body).to include(partner.operating_name)
      expect(response.body).to include(accredited_provider.operating_name)
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

    it "cannot save the same type twice for the same partner" do
      create(:partnership, accredited_provider: accredited_provider, provider: partner)

      expect { post step_path("check-your-answers") }.not_to change(Partnership, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("already part of another current or scheduled partnership")
    end
  end

  describe "when the journey has not been started" do
    it "returns the user to the first step from check your answers" do
      get step_path("check-your-answers")

      expect(response).to redirect_to(step_path("find-partner"))
    end
  end
end
