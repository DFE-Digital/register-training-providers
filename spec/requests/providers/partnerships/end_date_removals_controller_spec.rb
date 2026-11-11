require "rails_helper"

RSpec.describe "Provider partnership end date removal confirmation", type: :request do
  include DfESignInUserHelper

  let(:user) { create(:user) }

  before do
    user_exists_in_dfe_sign_in(user:)
    get "/auth/dfe/callback"
  end

  after { OmniAuth.config.mock_auth.clear }

  let(:provider) { create(:provider, :accredited) }
  let(:partner) { create(:provider, :hei_without_accreditation, operating_name: "Partner College") }
  let!(:partnership) do
    create(:partnership, accredited_provider: provider, provider: partner,
                         duration: Date.new(2024, 9, 1)...Date.new(2027, 7, 31))
  end
  let!(:academic_year) { create(:academic_year) }

  def step_path(step)
    provider_partnership_edit_step_path(provider_id: provider.id, partnership_id: partnership.id, step: step)
  end

  def confirmation_path
    provider_partnership_end_date_removal_path(partnership, provider_id: provider.id)
  end

  def submit_start_date
    get step_path("start-date")
    patch step_path("start-date"), params: {
      start_date: {
        "start_date(3i)" => "1",
        "start_date(2i)" => "9",
        "start_date(1i)" => "2024"
      }
    }
  end

  def submit_no_end_date
    submit_start_date
    patch step_path("end-date-question"), params: { end_date_question: { has_end_date: "false" } }
  end

  it "asks for confirmation when an existing end date is removed" do
    submit_no_end_date

    expect(response).to redirect_to(confirmation_path)
  end

  it "shows the design copy" do
    submit_no_end_date
    follow_redirect!

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Are you sure you want to remove the partnership end date?")
    expect(response.body).to include("This partnership will no longer have an end date.")
    expect(response.body).to include(">Remove end date<")
  end

  it "continues the journey when the removal is confirmed" do
    submit_no_end_date
    follow_redirect!

    post confirmation_path

    expect(response).to redirect_to(step_path("academic-years"))
  end

  it "returns to the end date question when cancelled" do
    submit_no_end_date
    follow_redirect!

    cancel = Nokogiri::HTML(response.body).css("a").find { |a| a.text.strip == "Cancel" }
    expect(cancel["href"]).to eq(step_path("end-date-question"))
  end

  it "returns to the end date question when the end date is kept" do
    submit_start_date
    patch step_path("end-date-question"), params: { end_date_question: { has_end_date: "true" } }

    expect(response).to redirect_to(step_path("end-date"))
  end

  it "does not ask when the partnership has no end date" do
    partnership.update!(duration: Date.new(2024, 9, 1)..)
    submit_no_end_date

    expect(response).to redirect_to(step_path("academic-years"))
  end

  it "returns to the question when nothing is being removed" do
    get confirmation_path

    expect(response).to redirect_to(step_path("end-date-question"))
  end
end
