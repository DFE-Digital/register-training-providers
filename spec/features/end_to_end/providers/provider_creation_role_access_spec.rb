require "rails_helper"

RSpec.feature "Provider creation role access" do
  scenario "REG can create accredited or unaccredited providers" do
    given_i_am_authenticated(user: create(:user, :reg))

    visit new_provider_is_the_provider_accredited_path

    expect(page.status_code).to eq(200)
    expect(page).to have_css('input[type="radio"]', count: 2)
    expect(page).to have_content("Is the provider accredited?")
  end

  scenario "MR is limited to accredited providers" do
    given_i_am_authenticated(user: create(:user, :mr))

    visit new_provider_is_the_provider_accredited_path

    expect(page.status_code).to eq(200)
    expect(page).to have_content("The provider is accredited")
    expect(page).to have_content(/can only add\s+accredited/)
    expect(page).not_to have_css('input[type="radio"]')
    expect(page).to have_css(
      'input[type="hidden"][name="provider[accreditation_status]"][value="accredited"]',
      visible: :all,
    )

    click_on "Continue"

    expect(page).to have_current_path(new_provider_type_path)
  end

  scenario "BAT is limited to unaccredited providers" do
    given_i_am_authenticated(user: create(:user, :bat))

    visit new_provider_is_the_provider_accredited_path

    expect(page.status_code).to eq(200)
    expect(page).to have_content("The provider is not accredited")
    expect(page).to have_content(/can only add\s+unaccredited/)
    expect(page).not_to have_css('input[type="radio"]')
    expect(page).to have_css(
      'input[type="hidden"][name="provider[accreditation_status]"][value="unaccredited"]',
      visible: :all,
    )

    click_on "Continue"

    expect(page).to have_current_path(new_provider_type_path)
  end

  scenario "RO cannot start provider creation" do
    given_i_am_authenticated(user: create(:user, :ro))

    visit new_provider_onboarding_path

    expect(page.status_code).to eq(403)
  end

  scenario "an API user cannot start provider creation" do
    given_i_am_an_authenticated_api_user

    visit new_provider_onboarding_path

    expect(page.status_code).to eq(403)
  end
end
