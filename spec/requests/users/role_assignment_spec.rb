RSpec.describe "User role assignment", type: :request do
  include DfESignInUserHelper

  it "does not let a non-REG user change another user's role" do
    stub_user_admin_policy
    stub_user_scope
    actor = create(:user, :ro)
    target = create(:user, :mr)
    sign_in_as(actor)

    patch user_path(target), params: { user: { role: "bat" } }
    patch user_check_path(target)

    expect(target.reload.role).to eq("mr")
  end

  it "lets a REG user change another user's role" do
    actor = create(:user, :reg)
    target = create(:user, :mr)
    sign_in_as(actor)

    patch user_path(target), params: { user: { role: "bat" } }
    patch user_check_path(target)

    expect(target.reload.role).to eq("bat")
  end

  it "defaults an API user converted to an internal user to read-only" do
    actor = create(:user, :reg)
    target = create(:user, api_user: true)
    sign_in_as(actor)

    patch user_path(target), params: { user: { api_user: "false" } }
    patch user_check_path(target)

    expect(target.reload.api_user?).to be false
    expect(target.role).to eq(UserRoleEnum::RO)
  end

  describe "the new user form" do
    it "preselects the Register role" do
      sign_in_as(create(:user, :reg))

      get new_user_path

      expect(response).to have_http_status(:ok)
      expect(Capybara.string(response.body).has_checked_field?("Register")).to be true
    end
  end

  context "when the last-REG guard is exercised directly" do
    it "blocks deactivating the last active REG" do
      allow_any_instance_of(UserPolicy).to receive(:update?).and_return(true)
      allow_any_instance_of(UserPolicy::Scope).to receive(:resolve).and_return(User.kept)
      actor = create(:user, :ro)
      target = create(:user, :reg)
      create_list(:user, 3, :ro)
      sign_in_as(actor)

      patch user_path(target), params: { user: { active: "false" } }
      patch user_check_path(target)

      expect(response).to have_http_status(:conflict)
      expect(target.reload.active?).to be true
    end

    it "blocks demoting the last active REG and logs the guard payload" do
      stub_user_admin_policy
      actor = create(:user, :reg)
      sign_in_as(actor)

      patch user_path(actor), params: { user: { role: "mr" } }

      expect(Rails.logger).to receive(:warn).with(
        event: "minimum_reg_users_violation",
        user_id: actor.id,
        remaining_active_reg_users: 0,
        total_users: 1,
        controller: "check",
        action: "update",
        path: user_check_path(actor),
      )

      patch user_check_path(actor)

      expect(response).to have_http_status(:conflict)
      expect(response.body).to include("You cannot remove the last Register user")
      expect(actor.reload.role).to eq("reg")
    end

    it "re-checks the last-REG guard against the state committed before the lock" do
      actor = create(:user, :reg)
      target = create(:user, :mr)
      create_list(:user, 3, :ro)
      sign_in_as(actor)

      simulate_concurrent_promotion_to_last_reg(target, actor)

      patch user_path(target), params: { user: { role: "bat" } }
      patch user_check_path(target)

      expect(response).to have_http_status(:conflict)
      expect(target.reload.role).to eq("mr")
    end

    it "blocks converting an internal user into an API user that would breach the minimum-active-users floor" do
      stub_user_admin_policy
      stub_user_scope
      actor = create(:user, :ro)
      target = create(:user, :mr)
      create_list(:user, 2, :ro)
      sign_in_as(actor)

      patch user_path(target), params: { user: { api_user: "true" } }
      patch user_check_path(target)

      expect(response).to have_http_status(:conflict)
      expect(response.body).to include("This change would leave too few active users")
      expect(target.reload.api_user?).to be false
    end

    it "blocks converting the last active REG into an API user and logs the guard payload" do
      allow_any_instance_of(UserPolicy).to receive(:update?).and_return(true)
      allow_any_instance_of(UserPolicy::Scope).to receive(:resolve).and_return(User.kept)
      actor = create(:user, :ro)
      target = create(:user, :reg)
      create_list(:user, 3, :ro)
      sign_in_as(actor)

      patch user_path(target), params: { user: { api_user: "true" } }

      expect(Rails.logger).to receive(:warn).with(
        event: "minimum_reg_users_violation",
        user_id: actor.id,
        remaining_active_reg_users: 0,
        total_users: 5,
        controller: "check",
        action: "update",
        path: user_check_path(target),
      )

      patch user_check_path(target)

      expect(response).to have_http_status(:conflict)
      expect(target.reload.role).to eq(UserRoleEnum::REG)
      expect(target.reload.api_user?).to be false
    end

    it "advances updated_at when a staged edit is confirmed" do
      actor = create(:user, :reg)
      target = create(:user, :mr)
      sign_in_as(actor)

      staged_at = target.updated_at

      patch user_path(target), params: { user: { first_name: "Confirmed" } }
      patch user_check_path(target)

      expect(target.reload.first_name).to eq("Confirmed")
      expect(target.updated_at).to be > staged_at
    end

    it "blocks deleting the last active REG" do
      stub_user_admin_policy(destroy: true)
      actor = create(:user, :ro)
      target = create(:user, :reg)
      create_list(:user, 3, :ro)
      sign_in_as(actor)

      delete user_delete_path(target)

      expect(response).to have_http_status(:conflict)
      expect(target.reload).to be_kept
    end
  end

private

  def stub_user_admin_policy(update: true, destroy: false)
    allow_any_instance_of(UserPolicy).to receive(:update?).and_return(update)
    allow_any_instance_of(UserPolicy).to receive(:destroy?).and_return(destroy)
  end

  def stub_user_scope
    allow_any_instance_of(UserPolicy::Scope).to receive(:resolve).and_return(User.kept)
  end

  def simulate_concurrent_promotion_to_last_reg(target, demoted_user)
    allow_any_instance_of(Users::CheckController).to receive(:lock_active_regs) do |_controller|
      User.where(id: target.id).update_all(role: UserRoleEnum::REG, active: true)
      User.where(id: demoted_user.id).update_all(role: UserRoleEnum::MR)
      User.kept.where(active: true, role: UserRoleEnum::REG).lock.load
    end
  end
end
