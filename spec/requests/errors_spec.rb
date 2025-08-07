require "rails_helper"

RSpec.describe "Error Pages", type: :request do
  describe "GET /404" do
    it "renders the 404 error page" do
      get "/404"
      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Page not found")
    end
  end

  describe "GET /422" do
    it "renders the 422 error page" do
      get "/422"
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Sorry, there’s a problem with the service")
    end
  end

  describe "GET /500" do
    it "renders the 500 error page" do
      get "/500"
      expect(response).to have_http_status(:internal_server_error)
      expect(response.body).to include("Sorry, there’s a problem with the service")
    end
  end
end
