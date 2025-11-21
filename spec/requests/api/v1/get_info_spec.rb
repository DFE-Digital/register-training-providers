require "rails_helper"

describe "`GET /info` endpoint", type: :request do
  let(:auth_token) { create(:authentication_token) }
  let(:token) { auth_token.token }

  before do
    get "/api/#{version}/info", headers: { Authorization: token }
  end

  context "using version v1" do
    let(:version) { "v1" }

    it_behaves_like "a register API endpoint", "/api/v1/info"

    it "shows the requested version" do
      expect(response.parsed_body).to eq({ "status" => "ok", "version" => { "latest" => "v1", "requested" => "v1" } })
    end
  end
end
