require "rails_helper"

RSpec.describe ApiClient, type: :model do
  let(:api_client) { create(:api_client) }
  subject { api_client }

  it { is_expected.to be_kept }

  context "api_client is discarded" do
    before do
      api_client.discard!
    end

    it "the api_client is discarded" do
      expect(api_client).to be_discarded
    end
  end

  describe "validations" do
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "before_discard callback" do
    let!(:active_token) { create(:authentication_token, api_client:) }
    let!(:expired_token) { create(:authentication_token, :expired, api_client:) }
    let!(:revoked_token) { create(:authentication_token, :revoked, api_client:) }

    it "revokes all active authentication tokens before discarding the client" do
      expect {
        api_client.discard!
      }.to change { active_token.reload.status }.from("active").to("revoked")

      expect(expired_token.reload.status).to eq("expired")
      expect(revoked_token.reload.status).to eq("revoked")
    end
  end
end
