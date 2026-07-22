RSpec.shared_examples "Rack::Attack Bearer token throttle", rack_attack: true, openapi: false do |path, limit: 300, period: 60.seconds|
  let(:headers) do
    {
      "X-Forwarded-For" => "192.0.2.2",
      "Authorization" => "Bearer #{token}"
    }
  end

  let(:auth_token) { create(:authentication_token) }
  let(:token) { auth_token.token }

  it "blocks requests after token limit" do
    Timecop.freeze(Time.zone.now) do
      limit.times do
        get(path, headers:)
        expect(response).to have_http_status(:ok)
      end

      get(path, headers:)
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  it "resets after period" do
    Timecop.freeze(Time.zone.now) do
      limit.times do
        get(path, headers:)
        expect(response).to have_http_status(:ok)
      end

      get(path, headers:)
      expect(response).to have_http_status(:too_many_requests)

      Timecop.freeze(Time.zone.now + period + 1.second) do
        get(path, headers:)
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
