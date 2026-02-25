require "rails_helper"

RSpec.describe AuthenticationToken, type: :model do
  let(:user) { create(:user) }
  let(:api_client) { create(:api_client) }

  subject(:authentication_token) { create(:authentication_token) }

  it do
    expect(subject).to define_enum_for(:status)
      .without_instance_methods.with_values({
        active: "active",
        expired: "expired",
        revoked: "revoked",
      }).backed_by_column_of_type(:string)
  end

  describe "associations" do
    it { is_expected.to belong_to(:api_client) }
    it { is_expected.to belong_to(:created_by) }
    it { is_expected.to belong_to(:revoked_by).optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:token_hash) }
    it { is_expected.to validate_uniqueness_of(:token_hash) }
    it { is_expected.to validate_presence_of(:expires_at) }

    it "rejects expires_at > 12 months from now" do
      too_far = 13.months.from_now.to_date
      token = build(:authentication_token, expires_at: too_far)
      expect(token).not_to be_valid
      expect(token.errors[:expires_at]).to include("must be between #{Time.current.to_date.to_fs(:govuk)} and #{1.year.from_now.to_date.to_fs(:govuk)}")
    end

    it "accepts expires_at <= 1 year" do
      valid_date = 11.months.from_now.to_date
      token = build(:authentication_token, expires_at: valid_date)
      expect(token).to be_valid
    end
  end

  describe "scopes" do
    let(:date) { 1.day.from_now }
    let(:yesterday) { Time.current.to_date }

    describe "::will_expire" do
      let!(:active_token) { create(:authentication_token) }
      let!(:active_token_will_expire_today) { create(:authentication_token, expires_at: date) }
      let!(:active_token_should_have_expired_yesterday) { create(:authentication_token, expires_at: yesterday) }
      let!(:active_token_will_expire_in_the_future) { create(:authentication_token, :will_expire) }
      let!(:expired_token) { create(:authentication_token, :expired, expires_at: yesterday) }
      let!(:revoked_token) { create(:authentication_token, :will_expire, :revoked) }

      context "when date is present" do
        Timecop.travel(1.day.from_now) do
          it "returns only the active tokens which will expire at the provided date" do
            expect(described_class.will_expire(date)).to contain_exactly(
              active_token_will_expire_today, active_token_should_have_expired_yesterday
            )
          end
        end
      end

      context "when date is not present" do
        Timecop.travel(1.day.from_now) do
          it "returns all the active tokens with an expired_at date" do
            expect(described_class.will_expire).to contain_exactly(
              active_token,
              active_token_will_expire_today,
              active_token_should_have_expired_yesterday,
              active_token_will_expire_in_the_future,
            )
          end
        end
      end
    end

    describe "::due_for_expiry" do
      let!(:active_token_due_yesterday) { create(:authentication_token, expires_at: yesterday) }
      let!(:active_token_due_today) { create(:authentication_token, expires_at: date) }
      let!(:active_token_will_expire_in_the_future) { create(:authentication_token, :will_expire) }
      let!(:expired_token) { create(:authentication_token, :expired, expires_at: yesterday) }
      let!(:revoked_token) { create(:authentication_token, :revoked, expires_at: yesterday) }

      it "returns only active tokens due for expiry" do
        Timecop.travel(1.day.from_now) do
          expect(described_class.due_for_expiry).to contain_exactly(
            active_token_due_yesterday,
            active_token_due_today
          )
        end
      end
    end
  end

  describe "::hash_token" do
    let(:unhashed_token) { "test_#{SecureRandom.hex(32)}" }
    let(:hashed_token) { OpenSSL::HMAC.hexdigest("SHA256", described_class::SECRET_KEY, unhashed_token) }

    it "hashes the token with HMAC SHA256" do
      expect(described_class.hash_token(unhashed_token)).to eq(hashed_token)
    end
  end

  describe "::create_with_random_token" do
    let(:result) do
      described_class.create_with_random_token(
        api_client: api_client,
        created_by: user,
      )
    end
    let(:token) { "Bearer #{result.token}" }

    subject(:authentication_token) { result }

    it "creates a new AuthenticationToken" do
      expect(authentication_token).to be_persisted
      expect(authentication_token).to be_active
    end

    it "sets the token_hash" do
      token_hash = OpenSSL::HMAC.hexdigest(
        "SHA256", Rails.application.key_generator.generate_key("api-token:v1", 32), authentication_token.token
      )

      expect(authentication_token.token_hash).to eq(token_hash)
    end

    it "sets the provider_id" do
      expect(authentication_token.api_client_id).to eq(api_client.id)
    end

    it "includes the environment name in the token" do
      expect(token.split.last.split("_").first).to eq("test")
    end
  end

  describe "::authenticate" do
    context "when an HMAC token exists" do
      let!(:authentication_token) do
        described_class.create_with_random_token(
          api_client: api_client,
          created_by: user,
        )
      end

      it "returns the token" do
        expect(
          described_class.authenticate(authentication_token.token),
        ).to eq(authentication_token)
      end
    end

    context "when the token does not exist" do
      let(:token) { "test_#{SecureRandom.hex(32)}" }

      let!(:authentication_token) do
        create(:authentication_token)
      end

      it "returns nil" do
        expect(described_class.authenticate(token)).to be_nil
      end
    end
  end

  describe "events" do
    before do
      Current.user = user
    end

    after do
      Current.user = nil
    end

    describe ".revoke!" do
      let(:current_date) { Time.current.to_date }

      it "revokes the token" do
        Timecop.freeze(current_date) do
          subject.revoke!

          expect(subject.revoked?).to be(true)
          expect(subject.revoked_by).to eq(user)
          expect(subject.revoked_at).to eq(current_date)
        end
      end
    end

    describe ".expire!" do
      it "revokes the token" do
        subject.expire!

        expect(subject.expired?).to be(true)
      end
    end
  end

  describe ".update_last_used_at!" do
    subject(:authentication_token) { create(:authentication_token, last_used_at:) }

    context "when the token has been used previously during the current day" do
      let(:last_used_at) { Time.zone.local(2025, 3, 15, 1) }

      it "does not update last_used_at" do
        Timecop.travel(Time.zone.local(2025, 3, 15, 2)) do
          subject.update_last_used_at!
          expect(subject.last_used_at).to eq(last_used_at)
        end
      end
    end

    context "when the token has not been used previously during the current day" do
      let(:last_used_at) { 1.day.ago }

      it "updates last_used_at" do
        Timecop.freeze do
          subject.update_last_used_at!
          expect(subject.last_used_at).to be_within(1.second).of(Time.current)
        end
      end
    end
  end
end
