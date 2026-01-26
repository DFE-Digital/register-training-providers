RSpec.shared_examples "a register API endpoint" do |url|
  let(:auth_token) { create(:authentication_token) }
  let(:token) { auth_token.token }

  subject(:make_request) do
    get url, headers: { Authorization: token }
    response
  end

  # NOTE: For openapi documentation
  it "returns 200 OK", openapi: { summary: "Successful request", tags: ["Core"] } do
    expect(make_request).to have_http_status(:ok)
  end
  it "returns 401 Unauthorized for invalid token", openapi: { summary: "Unauthorized request", tags: ["Core"] } do
    allow(auth_token).to receive(:token).and_return("invalid")

    expect(make_request).to have_http_status(:unauthorized)
  end

  # NOTE: Not for openapi documentation
  it "returns 404 Not Found for invalid version", openapi: false do
    next_version_url = url.sub(%r{/v(\d+)/}) { "/v#{Regexp.last_match(1).to_i + 1}/" }
    get next_version_url, headers: { Authorization: token }
    expect(response).to have_http_status(:not_found)
  end

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
