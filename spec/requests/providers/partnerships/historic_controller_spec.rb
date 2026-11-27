require "rails_helper"

RSpec.describe "Provider partnership history", type: :request do
  include DfESignInUserHelper

  let(:user) { create(:user) }

  before do
    user_exists_in_dfe_sign_in(user:)
    get "/auth/dfe/callback"
  end

  after { OmniAuth.config.mock_auth.clear }

  let(:provider) { create(:provider, :accredited) }
  let(:current_partner) { create(:provider, :hei_without_accreditation, operating_name: "Current College") }
  let(:historic_partner) { create(:provider, :school, operating_name: "Historic School") }

  let!(:current_partnership) do
    create(:partnership, accredited_provider: provider, provider: current_partner, duration: 1.month.ago..)
  end
  let!(:historic_partnership) do
    create(:partnership,
           accredited_provider: provider,
           provider: historic_partner,
           duration: Date.new(2020, 9, 1)...Date.new(2021, 7, 31),
           partnership_type: PartnershipTypeEnum::TRAINING_AND_DELIVERY)
  end

  describe "the partnerships tab" do
    it "does not link to history when there is none" do
      historic_partnership.discard!

      get provider_partnerships_path(provider)

      expect(response.body).to include("Current partnerships")
      expect(response.body).not_to include("View historic partnerships")
    end

    it "lists only current partnerships and links to the historic ones" do
      get provider_partnerships_path(provider)

      expect(response.body).to include("Current partnerships")
      expect(response.body).to include("View historic partnerships (1)")
      expect(response.body).to include(current_partner.operating_name)
      expect(response.body).not_to include(historic_partner.operating_name)
    end
  end

  describe "the historic partnerships page" do
    it "lists ended partnerships with their types and dates" do
      get provider_historic_partnerships_path(provider)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Historic partnerships")
      expect(response.body).to include("Previous partnerships for this provider.")
      expect(response.body).to include(historic_partner.operating_name)
      expect(response.body).to include("Training and Delivery")
      expect(response.body).to include("1 September 2020")
      expect(response.body).to include("31 July 2021")
      expect(response.body).not_to include(current_partner.operating_name)
    end

    it "lists the previous version when a partnership's types change" do
      current_partnership.sync_partnership_types([PartnershipTypeEnum::TRAINING_AND_DELIVERY])
      current_partnership.save!

      current_partnership.revise_types!(
        [PartnershipTypeEnum::RECRUITMENT],
        academic_years: current_partnership.academic_years,
        end_date: nil
      )

      get provider_historic_partnerships_path(provider)

      expect(response.body).to include(current_partner.operating_name)
      expect(response.body).to include("Training and Delivery")
      expect(response.body).to include(Time.zone.today.to_fs(:govuk))

      get provider_partnerships_path(provider)

      expect(response.body).to include(current_partner.operating_name)
      expect(response.body).to include("Recruitment")
    end

    it "shows an empty state when there is no history" do
      historic_partnership.destroy!

      get provider_historic_partnerships_path(provider)

      expect(response.body).to include("There are no historic partnerships")
    end
  end
end
