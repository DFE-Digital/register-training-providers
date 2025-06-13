require "rails_helper"

RSpec.describe "heartbeat requests", type: :request do
  describe "GET /ping" do
    it "returns PONG" do
      get "/ping"

      expect(response.body).to eq "PONG"
    end
  end

  describe "GET /healthcheck" do
    before do
      allow(ActiveRecord::Base.connection).to receive(:active?).and_return(true)
    end

    context "when everything is ok" do
      it "returns HTTP success" do
        get "/healthcheck"

        expect(response).to have_http_status :ok
      end

      it "returns JSON" do
        get "/healthcheck"
        expect(response.media_type).to eq("application/json")
      end

      it "returns the expected response report" do
        get "/healthcheck"

        expect(response.body).to eq({ checks: {
          database: true
        } }.to_json)
      end
    end

    context "there's no db connection" do
      before do
        allow(ActiveRecord::Base)
          .to receive(:connected?).and_return(false)
      end

      it("returns 503") do
        get "/healthcheck"

        expect(response).to have_http_status :service_unavailable
      end
    end
  end

  describe "GET /sha", env: { commit_sha: "deadbeef" } do
    it "returns the sha from the env var COMMIT_SHA" do
      get "/sha"

      expect(response.body).to eq '{"sha":"deadbeef"}'
    end
  end
end
