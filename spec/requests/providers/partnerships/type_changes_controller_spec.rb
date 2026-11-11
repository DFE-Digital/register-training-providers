require "rails_helper"

RSpec.describe "Provider partnership type change confirmation", type: :request do
  include DfESignInUserHelper

  let(:user) { create(:user) }

  before do
    user_exists_in_dfe_sign_in(user:)
    get "/auth/dfe/callback"
  end

  after { OmniAuth.config.mock_auth.clear }

  let(:provider) { create(:provider, :accredited) }
  let(:partner) { create(:provider, :hei_without_accreditation, operating_name: "Partner College") }
  let!(:partnership) { create(:partnership, accredited_provider: provider, provider: partner) }
  let!(:academic_year) { create(:academic_year) }

  def step_path(step)
    provider_partnership_edit_step_path(provider_id: provider.id, partnership_id: partnership.id, step: step)
  end

  def confirmation_path
    provider_partnership_type_change_path(partnership, provider_id: provider.id)
  end

  before do
    partnership.partnership_types.create!(partnership_type: PartnershipTypeEnum::TRAINING_AND_DELIVERY)
  end

  it "asks for confirmation when an existing type is removed" do
    get step_path("types")
    patch step_path("types"), params: { types: { partnership_types: [PartnershipTypeEnum::TRAINING_AND_DELIVERY] } }

    expect(response).to redirect_to(confirmation_path)
  end

  it "names the removed type and says the partnership ends today" do
    get step_path("types")
    patch step_path("types"), params: { types: { partnership_types: [PartnershipTypeEnum::TRAINING_AND_DELIVERY] } }
    follow_redirect!

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Are you sure you want to remove the recruitment type?")
    expect(response.body).to include("Ending this partnership type will be today, #{Time.zone.today.to_fs(:govuk)}.")
    expect(response.body).to include("The partnership will then appear in historic partnerships.")
    expect(response.body).to include(">Remove<")
  end

  it "asks for confirmation when a type is added" do
    get step_path("types")
    patch step_path("types"),
          params: { types: { partnership_types: [PartnershipTypeEnum::RECRUITMENT,
                                                 PartnershipTypeEnum::TRAINING_AND_DELIVERY,
                                                 PartnershipTypeEnum::STUDENT_FEE_MANAGEMENT] } }
    follow_redirect!

    expect(response.body).to include("Are you sure you want to add the student fee management type?")
    expect(response.body).to include("Adding this partnership type will end the current partnership today, " \
                                     "#{Time.zone.today.to_fs(:govuk)}.")
    expect(response.body).to include(">Add<")
  end

  it "asks for confirmation when types are both added and removed" do
    get step_path("types")
    patch step_path("types"),
          params: { types: { partnership_types: [PartnershipTypeEnum::RECRUITMENT,
                                                 PartnershipTypeEnum::STUDENT_FEE_MANAGEMENT] } }
    follow_redirect!

    expect(response.body).to include("Are you sure you want to change the partnership types?")
    expect(response.body).to include("Changing these partnership types will end the current partnership today, " \
                                     "#{Time.zone.today.to_fs(:govuk)}.")
    expect(response.body).to include(">Change<")
  end

  it "continues the journey when the change is confirmed" do
    get step_path("types")
    patch step_path("types"), params: { types: { partnership_types: [PartnershipTypeEnum::TRAINING_AND_DELIVERY] } }
    follow_redirect!

    post confirmation_path

    expect(response).to redirect_to(step_path("start-date"))
  end

  it "returns to the types step when cancelled" do
    get step_path("types")
    patch step_path("types"), params: { types: { partnership_types: [PartnershipTypeEnum::TRAINING_AND_DELIVERY] } }
    follow_redirect!

    cancel = Nokogiri::HTML(response.body).css("a").find { |a| a.text.strip == "Cancel" }
    expect(cancel["href"]).to eq(step_path("types"))
  end

  it "does not ask for confirmation when the types are unchanged" do
    get step_path("types")
    patch step_path("types"),
          params: { types: { partnership_types: [PartnershipTypeEnum::RECRUITMENT,
                                                 PartnershipTypeEnum::TRAINING_AND_DELIVERY] } }

    expect(response).to redirect_to(step_path("start-date"))
  end

  it "returns to the types step when nothing has changed" do
    get confirmation_path

    expect(response).to redirect_to(step_path("types"))
  end

  it "asks for confirmation when several types are removed" do
    partnership.partnership_types.create!(partnership_type: PartnershipTypeEnum::STUDENT_FEE_MANAGEMENT)

    get step_path("types")
    patch step_path("types"), params: { types: { partnership_types: [PartnershipTypeEnum::RECRUITMENT] } }
    follow_redirect!

    expect(response.body)
      .to include("Are you sure you want to remove the training and delivery and student fee management types?")
    expect(response.body).to include("Ending these partnership types will be today")
  end
end
