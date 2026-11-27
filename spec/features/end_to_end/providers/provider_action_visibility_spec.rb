require "rails_helper"

RSpec.feature "Provider action visibility" do
  def status_change_path(provider)
    provider_change_step_path(provider_id: provider.id, field: "status", step: "new-status")
  end

  scenario "RO sees no provider or status actions" do
    provider = create(:provider)

    given_i_am_authenticated(user: create(:user, :ro))
    visit provider_path(provider)

    expect(page).to have_current_path(provider_path(provider))
    expect(page).to have_title(provider.operating_name)
    expect(page).to have_content("You can view this provider's information and history but cannot make changes.")
    expect(page).to have_content("Contact BAT Support to request a change.")
    expect(page).not_to have_link("Archive provider")
    expect(page).not_to have_link(href: status_change_path(provider))
  end

  scenario "BAT sees no actions on an accredited provider" do
    provider = create(:provider, :accredited)

    given_i_am_authenticated(user: create(:user, :bat))
    visit provider_path(provider)

    expect(page).to have_current_path(provider_path(provider))
    expect(page).to have_title(provider.operating_name)
    expect(page).to have_content("Read-only access.")
    expect(page).to have_content("Only authorised Market Regulation users can make changes.")
    expect(page).to have_content("Contact Market Regulation to request a change.")
    expect(page).not_to have_link("Archive provider")
    expect(page).not_to have_link(href: status_change_path(provider))
  end

  scenario "MR sees no status action on an unaccredited provider" do
    provider = create(:provider)

    given_i_am_authenticated(user: create(:user, :mr))
    visit provider_path(provider)

    expect(page).not_to have_link(href: status_change_path(provider))
  end

  scenario "REG sees the status change action" do
    provider = create(:provider)

    given_i_am_authenticated(user: create(:user, :reg))
    visit provider_path(provider)

    expect(page).to have_link(href: status_change_path(provider))
  end

  scenario "MR sees no delete or restore action for an archived provider" do
    provider = create(:provider, :archived)

    given_i_am_authenticated(user: create(:user, :mr))
    visit provider_path(provider)

    expect(page).to have_current_path(provider_path(provider))
    expect(page).to have_title(provider.operating_name)
    expect(page).not_to have_link("Restore provider")
    expect(page).not_to have_link("Delete provider")
  end
end
