require "rails_helper"

RSpec.describe "`GET /providers` endpoint", type: :request do
  version = "v0"

  it_behaves_like "a register API endpoint", "/api/#{version}/providers"

  openapi = {
    summary: "Get many providers",
    tags: ["providers"]
  }

  context "response content" do
    let(:auth_token) { create(:authentication_token) }
    let(:token) { auth_token.token }

    let(:params) do
      { changed_since: 1.day.ago.utc.iso8601,
        academic_year: AcademicYearHelper.current_academic_year, }
    end

    let(:headers) { { Authorization: token } }

    it "returns an array of training providers", openapi: do
      create(:provider, :accredited, academic_years_active: [AcademicYearHelper.next_academic_year, AcademicYearHelper.previous_academic_year])
      create(:provider, :accredited, updated_at: 3.days.ago)
      latest_provider = create(:provider, :accredited)

      get("/api/#{version}/providers", headers:, params:)

      expect(response).to have_http_status(:ok)

      expect(response.parsed_body[:data].count).to be(1)
      expect(response.parsed_body[:data].first).to eq(
        { "id" => latest_provider.id,
          "operating_name" => latest_provider.operating_name,
          "provider_type" => latest_provider.provider_type,
          "code" => latest_provider.code,
          "accreditation_status" => latest_provider.accreditation_status,
          "updated_at" => latest_provider.updated_at.utc.iso8601, }
      )
    end
  end
end
