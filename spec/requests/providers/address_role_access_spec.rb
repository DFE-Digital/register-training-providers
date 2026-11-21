require "rails_helper"

RSpec.describe "Provider address role access", type: :request do
  include DfESignInUserHelper

  let(:accredited_provider) { create(:provider, :accredited) }
  let(:address) { create(:address, provider: accredited_provider) }

  describe "updating an address" do
    it "denies RO" do
      sign_in_as(create(:user, :ro))

      patch provider_address_path(address, provider_id: accredited_provider.id),
            params: { address: { address_line_1: "Changed" } }

      expect(response).to have_http_status(:forbidden)
    end

    it "denies BAT on an accredited provider" do
      sign_in_as(create(:user, :bat))

      patch provider_address_path(address, provider_id: accredited_provider.id),
            params: { address: { address_line_1: "Changed" } }

      expect(response).to have_http_status(:forbidden)
    end

    it "permits MR on an accredited provider" do
      sign_in_as(create(:user, :mr))

      patch provider_address_path(address, provider_id: accredited_provider.id),
            params: { address: { address_line_1: "Changed" } }

      expect(response).not_to have_http_status(:forbidden)
    end
  end

  describe "changing an address type" do
    it "denies RO" do
      sign_in_as(create(:user, :ro))

      post provider_addresses_types_path(provider_id: accredited_provider.id),
           params: { types: { types: ["school"] } }
      expect(response).to have_http_status(:forbidden)

      patch provider_update_address_types_path(address, provider_id: accredited_provider.id),
            params: { types: { types: ["school"] } }
      expect(response).to have_http_status(:forbidden)
    end

    it "denies BAT on an accredited provider" do
      sign_in_as(create(:user, :bat))

      patch provider_update_address_types_path(address, provider_id: accredited_provider.id),
            params: { types: { types: ["school"] } }

      expect(response).to have_http_status(:forbidden)
    end
  end
end
