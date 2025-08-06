RSpec.describe "Session timeout", type: :request do
  before do
    get root_path
    session[:last_seen_at] = 25.minutes.ago
  end

  it "resets the session after 20 minutes of inactivity" do
    get root_path
    expect(session[:last_seen_at]).to be_within(1.second).of(Time.current)
  end
end
