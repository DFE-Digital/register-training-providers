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
    let!(:active_token1) { create(:authentication_token, api_client:) }
    let!(:active_token2) { create(:authentication_token, api_client:) }
    let!(:expired_token) { create(:authentication_token, :expired, api_client:) }
    let!(:revoked_token) { create(:authentication_token, :revoked, api_client:) }

    it "revokes all active tokens before discarding the client" do
      expect {
        api_client.discard!
      }.to change { active_token1.reload.status }.from("active").to("revoked")
       .and change { active_token2.reload.status }.from("active").to("revoked")

      expect(expired_token.reload.status).to eq("expired")
      expect(revoked_token.reload.status).to eq("revoked")
    end
  end

  describe "#expire_all_due_tokens!" do
    let!(:due_token1) { create(:authentication_token, api_client: api_client, expires_at: 1.day.ago) }
    let!(:due_token2) { create(:authentication_token, api_client: api_client, expires_at: Date.current) }
    let!(:active_future_token) { create(:authentication_token, api_client: api_client, expires_at: 10.days.from_now) }

    it "expires all tokens due for expiry for this client" do
      api_client.expire_all_due_tokens!

      expect(due_token1.reload.status).to eq("expired")
      expect(due_token2.reload.status).to eq("expired")
      expect(active_future_token.reload.status).to eq("active")
    end
  end

  describe ".sweep_all_tokens!" do
    let!(:discarded_client) { create(:api_client) }
    let!(:kept_client) { create(:api_client) }

    let!(:discarded_token1) { create(:authentication_token, api_client: discarded_client) }
    let!(:discarded_token2) { create(:authentication_token, api_client: discarded_client) }

    let!(:due_token1) { create(:authentication_token, api_client: kept_client, expires_at: 1.day.ago) }
    let!(:due_token2) { create(:authentication_token, api_client: kept_client, expires_at: Date.current) }
    let!(:active_future_token) { create(:authentication_token, api_client: kept_client, expires_at: 10.days.from_now) }

    before do
      discarded_client.discard!
    end

    it "revokes tokens for discarded clients and expires due tokens for kept clients" do
      ApiClient.sweep_all_tokens!

      expect(discarded_token1.reload.status).to eq("revoked")
      expect(discarded_token2.reload.status).to eq("revoked")

      expect(due_token1.reload.status).to eq("expired")
      expect(due_token2.reload.status).to eq("expired")
      expect(active_future_token.reload.status).to eq("active")
    end

    it "is idempotent" do
      ApiClient.sweep_all_tokens!
      expect(due_token1.reload.status).to eq("expired")
      expect(due_token2.reload.status).to eq("expired")

      ApiClient.sweep_all_tokens!
      expect(due_token1.reload.status).to eq("expired")
      expect(due_token2.reload.status).to eq("expired")
      expect(active_future_token.reload.status).to eq("active")
    end
  end
end
