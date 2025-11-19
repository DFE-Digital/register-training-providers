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
end
