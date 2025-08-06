require "rails_helper"

RSpec.describe "Session touch", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  it "updates last_seen_at on each request" do
    get root_path
    first_seen_at = session[:last_seen_at]

    travel 1.minute do
      get root_path
      expect(session[:last_seen_at]).to be > first_seen_at
    end
  end
end
