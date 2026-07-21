RSpec.describe "User deletion rate limit", type: :request do
  include DfESignInUserHelper

  let(:user) { create(:user) }
  let(:users_to_delete) { create_list :user, 3 }
  let(:user_fails_to_be_deleted) { create(:user) }

  before do
    user_exists_in_dfe_sign_in(user:)
    get "/auth/dfe/callback"
  end

  after do
    OmniAuth.config.mock_auth.clear
  end

  it "allows 3 deletes within 3 minutes but blocks the 4th" do
    Timecop.freeze(Time.zone.now) do
      users_to_delete.each do |user_to_delete|
        delete user_delete_path(user_to_delete)
        expect(response).to have_http_status(:redirect)
      end

      expect(Rails.logger).to receive(:warn).with(
        event: "too_many_requests",
        user_id: user.id,
        controller: "Users::DeletesController",
        action: "destroy",
        path: "/users/#{user_fails_to_be_deleted.id}/delete",
      )

      delete user_delete_path(user_fails_to_be_deleted)

      expect(response).to have_http_status(:too_many_requests)
    end
  end
end
