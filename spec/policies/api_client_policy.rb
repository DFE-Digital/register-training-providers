require "rails_helper"

RSpec.describe ApiClientPolicy do
  subject { described_class }

  permissions :show? do
    it "permits access if the api_client is kept" do
      api_client = create(:api_client)
      expect(subject).to permit(build(:api_client), api_client)
    end

    it "denies access if the api_client is discarded" do
      api_client = create(:api_client, :discarded)
      expect(subject).not_to permit(build(:api_client), api_client)
    end
  end

  permissions :edit?, :update? do
    it "permits access if the api_client is kept" do
      api_client = create(:api_client)
      expect(subject).to permit(build(:api_client), api_client)
    end

    it "denies access if the api_client is discarded" do
      api_client = create(:api_client, :discarded)
      expect(subject).not_to permit(build(:api_client), api_client)
    end
  end

  permissions :create? do
    it "permits access if the api_client is a new record" do
      api_client = build(:api_client)
      expect(subject).to permit(build(:api_client), api_client)
    end

    it "denies access if the api_client is persisted" do
      api_client = create(:api_client)
      expect(subject).not_to permit(build(:api_client), api_client)
    end
  end
end
