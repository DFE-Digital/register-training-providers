require "rails_helper"

RSpec.describe "Creating contact", type: :feature do
  before do
    given_i_am_an_authenticated_user
  end

  context "with valid data" do
    let(:provider) { create(:provider, :hei) }

    scenario "creates contact for provider" do
      visit provider_contacts_path(provider)

      expect(page).to have_content("There are no contacts for #{provider.operating_name}")

      within(".govuk-button-group") do
        click_link "Add contact"
      end

      expect(page).to have_content(provider.operating_name)
      expect(page).to have_content("contact")

      expect(TemporaryRecord.count).to eq(0)

      fill_in "First name", with: "Manisha"
      fill_in "Last name", with: "Patel"
      fill_in "Email address", with: "manisha@provider.org"
      fill_in "Phone number", with: "0121 211 2121"

      click_button "Continue"

      expect(TemporaryRecord.count).to eq(1)
      expect(page).to have_content("Manisha")
      expect(page).to have_content("Patel")
      expect(page).to have_content("manisha@provider.org")
      expect(page).to have_content("0121 211 2121")

      click_button "Save contact"

      expect(TemporaryRecord.count).to eq(0)
      expect(page).to have_content("Contact added")
      expect(page).to have_content("Manisha")

      provider.reload
      expect(provider.contacts.count).to eq(1)

      contact = provider.contacts.first
      expect(contact.first_name).to eq("Manisha")
      expect(contact.last_name).to eq("Patel")
      expect(contact.email).to eq("manisha@provider.org")
      expect(contact.telephone_number).to eq("0121 211 2121")
    end
  end

  context "cancellation flow" do
    let(:provider) { create(:provider, :hei) }

    scenario "can cancel and return to contacts" do
      visit new_provider_contact_path(provider_id: provider.id)

      fill_in "First name", with: "Manisha"

      click_link "Cancel"

      expect(page).to have_current_path(provider_contacts_path(provider))
      expect(TemporaryRecord.count).to eq(0)
    end
  end
end
