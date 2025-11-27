require "rails_helper"

RSpec.describe "`GET /info` endpoint", type: :request do
  version = "v0"

  it_behaves_like "a register API endpoint", "/api/#{version}/info"

  context "response content" do
    let(:auth_token) { create(:authentication_token) }
    let(:token) { auth_token.token }

    it "returns the requested and latest API version and status", openapi: { summary: "Provides general information about the API", tags: ["Info"] } do
      get "/api/#{version}/info", headers: { Authorization: token }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(
        "status" => "ok",
        "version" => { "latest" => "v0", "requested" => "v0" }
      )
    end
  end
end
