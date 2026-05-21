require "rails_helper"

RSpec.describe "`GET /info` endpoint", type: :request do
  version = "v0"

  it_behaves_like "a register API endpoint", "/api/#{version}/info"

  context "response content" do
    let(:auth_token) { create(:authentication_token, status:) }
    let(:token) { auth_token.token }

    context "with an active token" do
      let(:status) { :active }

      it "returns the requested and latest API version and status", openapi: { summary: "Provides general information about the API", tags: ["Info"] } do
        get "/api/#{version}/info", headers: { Authorization: token }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq(
          "status" => "ok",
          "version" => { "latest" => "v0", "requested" => "v0" }
        )
      end
    end

    context "with a revoked token" do
      let(:status) { :revoked }

      it "returns unauthorised" do
        get "/api/#{version}/info", headers: { Authorization: token }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with an expired token" do
      let(:status) { :expired }

      it "returns unauthorised" do
        get "/api/#{version}/info", headers: { Authorization: token }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
