require "rails_helper"

RSpec.describe Api::Clients::RevokeToken, type: :service do
  let(:api_client) { create(:api_client, :with_authentication_token) }
  let(:authentication_token) { api_client.authentication_tokens.first }

  subject { described_class.call(api_client:) }

  it "changes the token status to revoked" do
    expect(authentication_token.status).to eq("active")

    subject
    expect(authentication_token.reload.status).to eq("revoked")
  end
end
