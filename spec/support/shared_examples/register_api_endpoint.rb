RSpec.shared_examples "a register API endpoint" do |url|
  let(:auth_token) { create(:authentication_token) }
  let(:token) { auth_token.token }

  subject(:make_request) do
    get url, headers: { Authorization: token }
    response
  end

  context "for openapi documentation" do
    context "happy path" do
      it "returns 200 OK", openapi: { summary: "Successful request", tags: ["Core"] } do
        expect(make_request).to have_http_status(:ok)
      end
    end
    context "basic sad paths" do
      it "returns 401 Unauthorized for invalid token", openapi: { summary: "Unauthorized request", tags: ["Core"] } do
        allow(auth_token).to receive(:token).and_return("invalid")
        expect(make_request).to have_http_status(:unauthorized)
      end

      it "returns 404 Not Found for invalid version", openapi: { summary: "Invalid API version", tags: ["Core"] } do
        invalid_version_url = url.sub(/v\d+/, "v0")
        get invalid_version_url, headers: { Authorization: token }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  context "for non openapi documentation", openapi: false do
    context "feature flag disabled", env: { feature_flag_api?: false } do
      it "returns 404 when feature flag is off", openapi: false do
        expect(make_request).to have_http_status(:not_found)
      end
    end

    context "authentication token edge cases" do
      context "expired token" do
        before { auth_token.expire! }
        it "returns 401", openapi: false do
          expect(make_request).to have_http_status(:unauthorized)
        end
      end

      context "revoked token" do
        before { auth_token.revoke! }
        it "returns 401", openapi: false do
          expect(make_request).to have_http_status(:unauthorized)
        end
      end

      context "discarded API client token", openapi: false do
        before { auth_token.api_client.discard! }
        it "returns 401" do
          expect(make_request).to have_http_status(:unauthorized)
        end
      end
    end
  end
end
