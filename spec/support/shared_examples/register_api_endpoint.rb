RSpec.shared_examples "a register API endpoint" do |url|
  let(:auth_token) { super() || create(:authentication_token) }
  let(:token) { auth_token.token }

  # Define the request as the subject
  subject(:make_request) do
    get url, headers: { Authorization: token }
    response
  end

  context "with a valid authentication token" do
    it "returns status code 200" do
      expect(make_request).to have_http_status(:ok)
    end

    context "when the register_api feature flag is off", env: { feature_flag_api?: false } do
      it "returns status code 404" do
        expect(make_request).to have_http_status(:not_found)
      end
    end

    context "with an invalid version" do
      it "returns status code 404" do
        invalid_version_url = url.sub(/v[.0-9]+/, "v0.0")
        get invalid_version_url, headers: { Authorization: token }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  context "without a valid authentication token" do
    let(:token) { "Bearer fred" }

    it "returns status code 401" do
      expect(make_request).to have_http_status(:unauthorized)
    end
  end

  context "with an expired authentication token" do
    before { auth_token.expire! }

    it "returns status code 401" do
      expect(make_request).to have_http_status(:unauthorized)
    end
  end

  context "with a revoked authentication token" do
    before { auth_token.revoke! }

    it "returns status code 401" do
      expect(make_request).to have_http_status(:unauthorized)
    end
  end

  context "with discarded api client's authentication token" do
    before { auth_token.api_client.discard! }

    it "returns status code 401" do
      expect(make_request).to have_http_status(:unauthorized)
    end
  end

  context "with an expired authentication token" do
    before { auth_token.expire! }

    it "returns status code 401" do
      expect(make_request).to have_http_status(:unauthorized)
    end
  end

  context "with a revoked authentication token" do
    before { auth_token.revoke! }

    it "returns status code 401" do
      expect(make_request).to have_http_status(:unauthorized)
    end
  end

  context "with discarded api client's authentication token" do
    before { auth_token.api_client.discard! }

    it "returns status code 401" do
      expect(make_request).to have_http_status(:unauthorized)
    end
  end
end
