RSpec.shared_examples "a register API endpoint" do |url|
  context "with a valid authentication token" do
    let(:token) do
      super() || create(:authentication_token).token
    end

    before do
      get url, headers: { Authorization: token }
    end

    it "returns status code 200" do
      expect(response).to have_http_status(:ok)
    end

    context "when the register_api feature flag is off", env: { feature_flag_api?: false } do
      it "returns status code 404" do
        expect(response).to have_http_status(:not_found)
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
    before do
      get url, headers: { Authorization: "Bearer fred" }
    end

    it "returns status code 401" do
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "with an expired authentication token" do
    let(:token) do
      authentication_token = create(:authentication_token, expires_at: 1.day.ago)
      authentication_token.expire!
      authentication_token.token
    end

    it "returns status code 401" do
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "with revoked authentication token" do
    let(:token) do
      authentication_token = create(:authentication_token)
      authentication_token.revoke!
      authentication_token.token
    end

    it "returns status code 401" do
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "with discarded api client's authentication token" do
    let(:token) do
      authentication_token = create(:authentication_token)
      authentication_token.api_client.discard!
      authentication_token.token
    end

    it "returns status code 401" do
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
