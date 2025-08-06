RSpec.describe "Pages", type: :request do
  describe "GET /accessibility" do
    it "shows the accessibility statement" do
      get "/accessibility"
      expect(response).to be_successful
      expect(response.body).to include("Accessibility statement for the Register of training providers")
    end
  end

  describe "GET /privacy" do
    it "shows the privacy notice" do
      get "/privacy"
      expect(response).to be_successful
      expect(response.body).to include("Register of training providers privacy notice")
    end
  end

  describe "GET /cookies" do
    it "shows the cookies page" do
      get "/cookies"
      expect(response).to be_successful
      expect(response.body).to include("Cookies on the Register of training providers ")
    end
  end
end
