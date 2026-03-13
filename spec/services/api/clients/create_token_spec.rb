require "rails_helper"

RSpec.describe Api::Clients::CreateToken, type: :service do
  let(:user) { create(:user) }
  let(:client_name) { "Gov API" }
  let(:expiry) { 3.months.from_now.to_date.to_s }
  let(:user_email) { user.email }

  subject(:token) do
    described_class.call(
      client_name: client_name,
      created_by_email: user_email,
      expires_at: expiry
    )
  end

  describe ".call" do
    context "when API client does not exist" do
      it "creates a new API client and token" do
        expect { token }.to change(ApiClient, :count).by(1)
                           .and change(AuthenticationToken, :count).by(1)
        expect(token.api_client.name).to eq(client_name)
        expect(token.api_client.discarded?).to be false
        expect(token.created_by).to eq(user)
        expect(token.token).to be_present
        expect(token.status).to eq("active")
      end
    end

    context "when API client exists and is kept" do
      let!(:api_client) { create(:api_client, name: client_name) }

      it "uses the existing kept API client" do
        expect { token }.to change(AuthenticationToken, :count).by(1)
        expect(token.api_client).to eq(api_client)
        expect(token.api_client.discarded?).to be false
        expect(token.created_by).to eq(user)
      end
    end

    context "when a discarded API client exists" do
      let!(:discarded_client) { create(:api_client, name: client_name).discard }

      it "raises ActiveRecord::RecordInvalid" do
        expect { token }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "when expiry date is not provided" do
      let(:expiry) { nil }

      it "uses the model default expiry (6 months)" do
        expect(token.expires_at).to be_within(1.day).of(6.months.from_now.to_date)
      end
    end

    context "when expiry date is invalid" do
      let(:expiry) { "not-a-date" }

      it "raises an ArgumentError with inspected value" do
        expect {
          token
        }.to raise_error(ArgumentError, "Invalid expiry date: \"#{expiry}\"")
      end
    end

    context "when user does not exist" do
      let(:user_email) { "missing@example.com" }

      it "raises ActiveRecord::RecordNotFound" do
        expect { token }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when user is discarded" do
      before { user.discard }

      it "raises ActiveRecord::RecordNotFound" do
        expect { token }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with whitespace in expiry date" do
      let(:date) { 3.months.from_now.strftime("%Y-%m-%d") }
      let(:expiry) { " #{date} " }

      it "parses expiry correctly ignoring whitespace" do
        expect(token.expires_at).to eq(Date.parse(date))
      end
    end
  end
end
