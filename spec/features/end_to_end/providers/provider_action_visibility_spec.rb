require "rails_helper"

RSpec.feature "Provider action visibility" do
  scenario "RO sees no provider actions" do
    provider = create(:provider)

    given_i_am_authenticated(user: create(:user, :ro))
    visit provider_path(provider)

    expect(page).to have_current_path(provider_path(provider))
    expect(page).to have_title(provider.operating_name)
    expect(page).to have_content("You can view this provider's information and history but cannot make changes.")
    expect(page).not_to have_link("Archive provider")
    expect(page).not_to have_link("Mark as inactive")
  end

  scenario "BAT sees no archive action for an accredited provider" do
    provider = create(:provider, :accredited)

    given_i_am_authenticated(user: create(:user, :bat))
    visit provider_path(provider)

    expect(page).to have_current_path(provider_path(provider))
    expect(page).to have_title(provider.operating_name)
    expect(page).to have_content("You can view this provider's information and history but cannot make changes.")
    expect(page).not_to have_link("Archive provider")
    expect(page).not_to have_link("Mark as inactive")
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
