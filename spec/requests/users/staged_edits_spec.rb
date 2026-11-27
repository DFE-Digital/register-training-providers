RSpec.describe "User staged edits", type: :request do
  include DfESignInUserHelper

  let(:signed_in_user) { create(:user) }

  before do
    user_exists_in_dfe_sign_in(user: signed_in_user)
    get "/auth/dfe/callback"
  end

  it "does not rehydrate one user's staged edit onto another user" do
    user_a = create(:user, first_name: "Alpha")
    user_b = create(:user, first_name: "Beta")

    patch user_path(user_a), params: { user: { first_name: "Changed" } }
    get edit_user_path(user_b, goto: "confirm")

    expect(response.body).to include("Beta")
    expect(response.body).not_to include("Changed")
  end

  it "does not rehydrate an abandoned staged edit on a fresh edit visit" do
    user = create(:user, :mr)

    patch user_path(user), params: { user: { role: UserRoleEnum::BAT } }
    get edit_user_path(user)

    form = Capybara.string(response.body)
    expect(form.has_checked_field?(UserRoleEnum.label_for(UserRoleEnum::MR))).to be true
    expect(form.has_checked_field?(UserRoleEnum.label_for(UserRoleEnum::BAT))).to be false
  end

  it "rehydrates a staged edit when navigating back from the check page" do
    user = create(:user, :mr)

    patch user_path(user), params: { user: { role: UserRoleEnum::BAT } }
    get edit_user_path(user, goto: "confirm")

    form = Capybara.string(response.body)
    expect(form.has_checked_field?(UserRoleEnum.label_for(UserRoleEnum::BAT))).to be true
  end

  context "when the staged edit has expired" do
    let(:user) { create(:user, :mr) }

    before do
      patch user_path(user), params: { user: { role: UserRoleEnum::BAT } }
      expire_staged_edit
    end

    it "renders the check page for the committed user instead of raising" do
      get user_check_path(user)

      expect(response).to have_http_status(:ok)
    end

    it "renders the edit page when returning from the check page" do
      get edit_user_path(user, goto: "confirm")

      expect(response).to have_http_status(:ok)
    end

    it "refuses to save an expired staged edit" do
      patch user_check_path(user)

      expect(response).to redirect_to(edit_user_path(user, goto: "confirm"))
      expect(user.reload.role).to eq(UserRoleEnum::MR)
    end
  end

  it "refuses to confirm an edit whose staged record has been cleared" do
    user = create(:user, :mr)

    patch user_path(user), params: { user: { role: UserRoleEnum::BAT } }
    clear_staged_edit
    patch user_check_path(user)

    expect(response).to redirect_to(edit_user_path(user, goto: "confirm"))
    expect(flash[:success]).to be_nil
    expect(user.reload.role).to eq(UserRoleEnum::MR)
  end

private

  def expire_staged_edit
    TemporaryRecord.where(record_type: "User").update_all(expires_at: 2.days.ago)
  end

  def clear_staged_edit
    get users_path
  end
end
