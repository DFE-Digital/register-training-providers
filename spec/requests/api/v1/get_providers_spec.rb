require "rails_helper"

RSpec.describe "`GET /providers` endpoint", type: :request do
  version = "v1"

  it_behaves_like "a register API endpoint", "/api/#{version}/providers"

  context "response content" do
    let(:auth_token) { create(:authentication_token) }
    let(:token) { auth_token.token }

    it "returns an array of training providers", openapi:
    { summary: "Get many providers",
      tags: ["providers"],
      description: <<~DESC
        This endpoint can be used to retrieve providers for a given academic year.
        This is intended to make it possible to check for new or updated providers regularly.
      DESC
     } do
      provider = create(:provider)

      get "/api/#{version}/providers", headers: { Authorization: token }

      expect(response).to have_http_status(:ok)

      expect(response.parsed_body[:data].first).to eq(
        { "id" => provider.id,
          "operating_name" => provider.operating_name,
          "provider_type" => provider.provider_type,
          "code" => provider.code,
          "accreditation_status" => provider.accreditation_status,
          "updated_at" => provider.updated_at.iso8601, }
      )
    end
  end
end
