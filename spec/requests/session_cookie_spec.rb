require "rails_helper"

RSpec.describe "Session cookie config", type: :request do
  it "sets the session cookie with the correct name and expiry" do
    get root_path

    cookie = response.headers["Set-Cookie"]
    expect(cookie).to include("_register_of_training_providers_session")
    expect(cookie).to match(/expires=/i)
  end
end
