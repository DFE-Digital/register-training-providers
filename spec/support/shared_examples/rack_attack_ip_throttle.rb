RSpec.shared_examples "Rack::Attack IP throttle", rack_attack: true, openapi: false do |path, limit: 100, period: 60.seconds|
  let(:ip) { "192.0.2.1" }
  let(:headers) do
    {
      "X-Forwarded-For" => ip
    }
  end

  it "blocks requests after IP limit" do
    Timecop.freeze(Time.zone.now) do
      limit.times do
        get(path, headers:)
        expect(response).to have_http_status(:unauthorized)
      end

      get(path, headers:)
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  it "resets after period" do
    Timecop.freeze(Time.zone.now) do
      limit.times do
        get(path, headers:)
        expect(response).to have_http_status(:unauthorized)
      end

      get(path, headers:)
      expect(response).to have_http_status(:too_many_requests)

      Timecop.freeze(Time.zone.now + period + 1.second) do
        get(path, headers:)
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
