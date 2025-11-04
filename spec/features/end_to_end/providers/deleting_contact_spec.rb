require "rails_helper"

RSpec.describe "Deleting contact", type: :feature do
  before do
    given_i_am_an_authenticated_user
  end

  context "with an existing contact" do
    let(:provider) { create(:provider, :hei) }
    let!(:contact) do
      create(:contact,
             provider: provider,
             first_name: "First",
             last_name: "Lastname",
             email: "original@example.com",
             telephone_number: "0800 000 0000")
    end

    scenario "deletes contact for provider" do
      visit provider_contacts_path(provider)

      expect(page).to have_content("First")
      expect(page).to have_content("0800 000 0000")
      expect(provider.contacts.kept.count).to eq(1)

      click_link "Delete", match: :first

      expect(page).to have_content("Confirm you want to delete #{provider.operating_name}’s contact")
      expect(page).to have_content("Delete contact")

      expect(page).to have_content("First")
      expect(page).to have_content("Lastname")
      expect(page).to have_content("original@example.com")
      expect(page).to have_content("0800 000 0000")

      expect(page).to have_content("Deleting an contact is permanent – you cannot undo it.")

      expect(page).to have_link("Cancel", href: provider_contacts_path(provider))

      click_button "Delete contact"

      expect(current_path).to eq(provider_contacts_path(provider))

      expect(page).to have_content("Contact deleted")

      expect(page).not_to have_content("First Lastname")
      expect(page).to have_content("There are no contacts for #{provider.operating_name}")

      expect(provider.contacts.kept.count).to eq(0)
      expect(provider.contacts.count).to eq(1)
      expect(contact.reload.discarded?).to be true
    end

    scenario "cancels deletion and returns to contacts" do
      visit provider_contacts_path(provider)

      click_link "Delete", match: :first

      expect(page).to have_content("Confirm you want to delete #{provider.operating_name}’s contact")

      click_link "Cancel"

      expect(current_path).to eq(provider_contacts_path(provider))

      expect(page).to have_content("First")
      expect(page).to have_content("0800 000 0000")
      expect(provider.contacts.kept.count).to eq(1)
      expect(contact.reload.discarded?).to be false
    end
  end

  context "with multiple contacts" do
    let(:provider) { create(:provider, :hei) }
    let!(:contact1) do
      create(:contact,
             provider: provider,
             first_name: "First",
             last_name: "Lastname",
             email: "original@example.com",
             telephone_number: "0800 000 0000")
    end
    let!(:contact2) do
      create(:contact,
             provider: provider,
             first_name: "Second",
             last_name: "Lastname",
             email: "second@example.com",
             telephone_number: "0800 000 0001")
    end

    scenario "deletes one contact while keeping others" do
      visit provider_contacts_path(provider)

      expect(page).to have_content("First")
      expect(page).to have_content("Second")
      expect(provider.contacts.kept.count).to eq(2)

      within(".govuk-summary-card", text: "First Lastname") do
        click_link "Delete"
      end

      expect(page).to have_content("Confirm you want to delete #{provider.operating_name}’s contact")
      expect(page).to have_content("First")

      click_button "Delete contact"

      expect(current_path).to eq(provider_contacts_path(provider))

      expect(page).to have_content("Contact deleted")

      expect(page).not_to have_content("First Lastname")
      expect(page).to have_content("Second Lastname")
      expect(page).to have_content("Contacts (1)")

      expect(provider.contacts.kept.count).to eq(1)
      expect(provider.contacts.count).to eq(2)
      expect(contact1.reload.discarded?).to be true
      expect(contact2.reload.discarded?).to be false
    end
  end
end
