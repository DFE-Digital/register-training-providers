require "rails_helper"

RSpec.feature "Role-based provider UI" do
  let(:provider) { create(:provider) }

  scenario "RO sees no write controls" do
    given_i_am_authenticated(user: create(:user, :ro))

    visit providers_path
    expect(page).not_to have_link("Add provider")

    visit provider_path(provider)
    expect(page).to have_content("You can view this provider's information and history but cannot make changes.")
    expect(page).to have_link(href: provider_changes_field_history_path(provider_id: provider.id, field: "operating_name"))
    expect(page).not_to have_link(href: provider_change_step_path(provider_id: provider.id, field: "operating_name", step: "effective-date"))

    visit provider_accreditations_path(provider)
    expect(page).not_to have_link("Add accreditation")

    visit provider_partnerships_path(provider)
    expect(page).not_to have_link("Add partnership")

    visit provider_contacts_path(provider)
    expect(page).not_to have_link("Add contact")

    visit provider_addresses_path(provider)
    expect(page).not_to have_link("Add address")
    expect(page).to have_link("Historic addresses")
  end

  scenario "API user sees no write controls" do
    given_i_am_an_authenticated_api_user

    visit providers_path
    expect(page).not_to have_link("Add provider")

    visit provider_path(provider)
    expect(page).to have_content("You can view this provider's information and history but cannot make changes.")
    expect(page).not_to have_link(href: provider_change_step_path(provider_id: provider.id, field: "operating_name", step: "effective-date"))

    visit provider_accreditations_path(provider)
    expect(page).not_to have_link("Add accreditation")

    visit provider_partnerships_path(provider)
    expect(page).not_to have_link("Add partnership")

    visit provider_contacts_path(provider)
    expect(page).not_to have_link("Add contact")

    visit provider_addresses_path(provider)
    expect(page).not_to have_link("Add address")
    expect(page).to have_link("Historic addresses")
  end

  scenario "an archived training partner gets no partnership actions" do
    accredited_provider = create(:provider, :accredited)
    archived_partner = create(:provider, :archived)
    create(:partnership, provider: archived_partner, accredited_provider: accredited_provider)

    given_i_am_authenticated(user: create(:user, :reg))

    visit provider_partnerships_path(accredited_provider)

    expect(page).to have_content(archived_partner.operating_name)
    expect(page).not_to have_link("Change")
    expect(page).not_to have_link("Delete")
  end

  scenario "BAT sees no write controls on an accredited provider" do
    accredited_provider = create(:provider, :accredited)

    given_i_am_authenticated(user: create(:user, :bat))

    visit provider_path(accredited_provider)
    expect(page).not_to have_link(href: provider_change_step_path(provider_id: accredited_provider.id, field: "operating_name", step: "effective-date"))

    visit provider_accreditations_path(accredited_provider)
    expect(page).not_to have_link("Add accreditation")

    visit provider_partnerships_path(accredited_provider)
    expect(page).not_to have_link("Add partnership")

    visit provider_contacts_path(accredited_provider)
    expect(page).not_to have_link("Add contact")

    visit provider_addresses_path(accredited_provider)
    expect(page).not_to have_link("Add address")
  end

  scenario "RO sees no card actions" do
    accredited_provider = create(:provider, :accredited)
    create(:partnership, provider:)
    create(:contact, provider:)
    create(:address, provider:)

    given_i_am_authenticated(user: create(:user, :ro))

    visit provider_accreditations_path(accredited_provider)
    expect(page).not_to have_link("Change")
    expect(page).not_to have_link("Delete")

    visit provider_partnerships_path(provider)
    expect(page).not_to have_link("Change")
    expect(page).not_to have_link("Delete")

    visit provider_contacts_path(provider)
    expect(page).not_to have_link("Change")
    expect(page).not_to have_link("Delete")

    visit provider_addresses_path(provider)
    expect(page).not_to have_link("Change")
    expect(page).not_to have_link("Delete")
  end

  scenario "REG sees card actions on any provider" do
    accredited_provider = create(:provider, :accredited)
    create(:partnership, provider:)
    create(:contact, provider:)
    create(:address, provider:)

    given_i_am_authenticated(user: create(:user, :reg))

    visit provider_accreditations_path(accredited_provider)
    expect(page).to have_link("Change")
    expect(page).to have_link("Delete")

    visit provider_partnerships_path(provider)
    expect(page).to have_link("Change")
    expect(page).to have_link("Delete")

    visit provider_contacts_path(provider)
    expect(page).to have_link("Change")
    expect(page).to have_link("Delete")

    visit provider_addresses_path(provider)
    expect(page).to have_link("Change")
    expect(page).to have_link("Delete")
  end

  scenario "MR sees card actions on an accredited provider" do
    accredited_provider = create(:provider, :accredited)
    create(:partnership, provider: accredited_provider)
    create(:contact, provider: accredited_provider)
    create(:address, provider: accredited_provider)

    given_i_am_authenticated(user: create(:user, :mr))

    visit provider_accreditations_path(accredited_provider)
    expect(page).to have_link("Change")
    expect(page).to have_link("Delete")

    visit provider_partnerships_path(accredited_provider)
    expect(page).to have_link("Change")
    expect(page).to have_link("Delete")

    visit provider_contacts_path(accredited_provider)
    expect(page).to have_link("Change")
    expect(page).to have_link("Delete")

    visit provider_addresses_path(accredited_provider)
    expect(page).to have_link("Change")
    expect(page).to have_link("Delete")
  end

  scenario "BAT sees no accreditation or partnership actions but manages contacts and addresses" do
    accredited_provider = create(:provider, :accredited)
    create(:partnership, provider:)
    create(:contact, provider:)
    create(:address, provider:)

    given_i_am_authenticated(user: create(:user, :bat))

    visit provider_accreditations_path(accredited_provider)
    expect(page).to have_css(".govuk-summary-card")
    expect(page).not_to have_link("Change")
    expect(page).not_to have_link("Delete")

    visit provider_partnerships_path(provider)
    expect(page).to have_css(".govuk-summary-card")
    expect(page).not_to have_link("Change")
    expect(page).not_to have_link("Delete")

    visit provider_contacts_path(provider)
    expect(page).to have_link("Change")
    expect(page).to have_link("Delete")

    visit provider_addresses_path(provider)
    expect(page).to have_link("Change")
    expect(page).to have_link("Delete")
  end

  scenario "MR can manage accreditation and partnerships on an unaccredited provider" do
    given_i_am_authenticated(user: create(:user, :mr))

    visit provider_path(provider)
    expect(page).not_to have_link(href: provider_change_step_path(provider_id: provider.id, field: "operating_name", step: "effective-date"))
    expect(page).not_to have_content("cannot make changes.")

    visit provider_accreditations_path(provider)
    expect(page).to have_link("Add accreditation")

    visit provider_partnerships_path(provider)
    expect(page).to have_link("Add partnership")

    visit provider_contacts_path(provider)
    expect(page).not_to have_link("Add contact")

    visit provider_addresses_path(provider)
    expect(page).not_to have_link("Add address")
  end
end
