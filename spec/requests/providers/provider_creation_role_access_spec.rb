RSpec.describe "Provider creation role access", type: :request do
  include DfESignInUserHelper

  it "denies BAT creating an accredited provider" do
    sign_in_as(create(:user, :bat))

    post new_provider_is_the_provider_accredited_path, params: { provider: { accreditation_status: "accredited" } }

    expect(response).to have_http_status(:forbidden)
  end

  it "denies MR creating an unaccredited provider" do
    sign_in_as(create(:user, :mr))

    post new_provider_is_the_provider_accredited_path, params: { provider: { accreditation_status: "unaccredited" } }

    expect(response).to have_http_status(:forbidden)
  end

  it "offers only accredited providers to MR" do
    sign_in_as(create(:user, :mr))

    get new_provider_is_the_provider_accredited_path

    expect(response.body).to include('value="accredited"')
    expect(response.body).not_to include('value="unaccredited"')
    expect(response.body).not_to include('type="radio"')
  end

  it "offers only unaccredited providers to BAT" do
    sign_in_as(create(:user, :bat))

    get new_provider_is_the_provider_accredited_path

    expect(response.body).to include('value="unaccredited"')
    expect(response.body).not_to include('value="accredited"')
    expect(response.body).not_to include('type="radio"')
  end

  it "offers both statuses to REG" do
    sign_in_as(create(:user, :reg))

    get new_provider_is_the_provider_accredited_path

    expect(response.body).to include('value="accredited"')
    expect(response.body).to include('value="unaccredited"')
  end

  it "allows REG to continue with an accredited provider" do
    sign_in_as(create(:user, :reg))

    post new_provider_is_the_provider_accredited_path, params: { provider: { accreditation_status: "accredited" } }

    expect(response).to have_http_status(:redirect)
  end
end
