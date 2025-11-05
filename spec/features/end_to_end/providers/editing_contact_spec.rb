require "rails_helper"

RSpec.describe "Editing contact", type: :feature do
  before do
    given_i_am_an_authenticated_user
  end

  context "with valid data" do
    let(:provider) { create(:provider, :hei) }
    let!(:contact) do
      create(:contact,
             provider: provider,
             first_name: "First",
             last_name: "Lastname",
             email: "original@example.com",
             telephone_number: "0800 000 0000")
    end

    scenario "edits contact for provider" do
      visit provider_contacts_path(provider)

      expect(page).to have_content("First")
      expect(page).to have_content("0800 000 0000")

      click_link "Change", match: :first

      expect(page).to have_content(provider.operating_name)
      expect(page).to have_field("First name", with: "First")
      expect(page).to have_field("Last name", with: "Lastname")
      expect(page).to have_field("Email address", with: "original@example.com")
      expect(page).to have_field("Phone number (optional)", with: "0800 000 0000")

      expect(TemporaryRecord.count).to eq(0)

      fill_in "First name", with: "Newfirst"
      fill_in "Last name", with: "Newlastname"
      fill_in "Email address", with: "new@example.com"
      fill_in "Phone number (optional)", with: "0800 000 0001"

      click_button "Continue"

      expect(TemporaryRecord.count).to eq(1)
      expect(page).to have_content("Check your answers")
      expect(page).to have_content("Newfirst")
      expect(page).to have_content("Newlastname")
      expect(page).to have_content("new@example.com")
      expect(page).to have_content("0800 000 0001")

      click_button "Save contact"

      expect(TemporaryRecord.count).to eq(0)
      expect(page).to have_content("Contact updated")
      expect(page).to have_content("Newfirst")

      contact.reload
      expect(contact.first_name).to eq("Newfirst")
      expect(contact.last_name).to eq("Newlastname")
      expect(contact.email).to eq("new@example.com")
      expect(contact.telephone_number).to eq("0800 000 0001")
    end

    scenario "edits contact with minimal required fields only" do
      visit edit_provider_contact_path(contact, provider_id: provider.id)

      fill_in "First name", with: "Minname"
      fill_in "Last name", with: "Minlastname"
      fill_in "Email address", with: "min@example.com"
      fill_in "Phone number (optional)", with: ""

      click_button "Continue"

      expect(page).to have_content("Check your answers")
      expect(page).to have_content("Minname")
      expect(page).to have_content("Minlastname")
      expect(page).to have_content("min@example.com")

      click_button "Save contact"

      expect(page).to have_content("Contact updated")
      expect(provider.contacts.count).to eq(1)

      contact.reload
      expect(contact.first_name).to eq("Minname")
      expect(contact.last_name).to eq("Minlastname")
      expect(contact.email).to eq("min@example.com")
      expect(contact.telephone_number).to be_blank
    end
  end

  context "with invalid data" do
    let(:provider) { create(:provider, :hei) }
    let!(:contact) { create(:contact, provider:) }

    scenario "missing required fields shows errors" do
      visit edit_provider_contact_path(contact, provider_id: provider.id)

      fill_in "First name", with: ""
      fill_in "Last name", with: ""
      fill_in "Email address", with: ""

      click_button "Continue"

      expect(page).to have_error_summary("Enter first name", "Enter last name", "Enter email address")
      expect(TemporaryRecord.count).to eq(0)
    end

    scenario "email is in invalid format" do
      visit edit_provider_contact_path(contact, provider_id: provider.id)

      fill_in "Email address", with: "wrongformat"

      click_button "Continue"

      expect(page).to have_error_summary("Enter an email address in the correct format, like name@example.com")
      expect(TemporaryRecord.count).to eq(0)
    end

    scenario "Phone number is in invalid format" do
      visit edit_provider_contact_path(contact, provider_id: provider.id)

      fill_in "Phone number (optional)", with: "wrongformat"

      click_button "Continue"

      expect(page).to have_error_summary("Enter a Phone number, like 01632 960 001, 07700 900 982 or +44 808 157 0192")
      expect(TemporaryRecord.count).to eq(0)
    end
  end

  context "check answers flow" do
    let(:provider) { create(:provider, :hei) }
    let!(:contact) { create(:contact, provider: provider, first_name: "First") }

    scenario "can change values from check page and resubmit" do
      visit edit_provider_contact_path(contact, provider_id: provider.id)

      fill_in "First name", with: "Newname"
      fill_in "Phone number (optional)", with: "0800 000 0001"

      click_button "Continue"

      expect(page).to have_content("Check your answers")
      expect(page).to have_content("Newname")
      expect(page).to have_content("0800 000 0001")

      click_link "Change", match: :first

      expect(page).to have_field("First name", with: "Newname")
      expect(page).to have_field("Phone number (optional)", with: "0800 000 0001")

      fill_in "First name", with: "Newestname"

      click_button "Continue"

      expect(page).to have_content("Newestname")
      expect(page).to have_content("0800 000 0001")

      click_button "Save contact"

      expect(page).to have_content("Contact updated")
      expect(page).to have_content("Newestname")
    end

    scenario "can cancel and return to contacts" do
      visit edit_provider_contact_path(contact, provider_id: provider.id)

      fill_in "First name", with: "Wrongname"

      click_link "Cancel"

      expect(page).to have_current_path(provider_contacts_path(provider))
      expect(TemporaryRecord.count).to eq(0)

      contact.reload
      expect(contact.first_name).to eq("First")
    end
  end
end
