require "rails_helper"

RSpec.describe "Creating accreditation", type: :feature do
  before do
    given_i_am_an_authenticated_user
  end

  context "with valid data" do
    let(:provider) { create(:provider, :hei, :unaccredited) }

    scenario "HEI provider creates accreditation" do
      visit provider_accreditations_path(provider)

      expect(page).to have_content("There are no accreditations for #{provider.operating_name}")

      click_link "Add accreditation"

      expect(page).to have_content(provider.operating_name)
      expect(page).to have_content("Accreditation details")

      expect(TemporaryRecord.count).to eq(0)

      start_year = Date.current.year
      fill_in "Accredited provider number", with: "1234"
      within_fieldset("Date accreditation starts") do
        fill_in "Day", with: "1"
        fill_in "Month", with: "1"
        fill_in "Year", with: start_year.to_s
      end

      click_button "Continue"

      expect(TemporaryRecord.count).to eq(1)
      expect(page).to have_content("Check your answers")
      expect(page).to have_content("1234")
      expect(page).to have_content("1 January #{start_year}")
      expect(page).to have_content("Not entered")

      click_button "Save accreditation"

      expect(TemporaryRecord.count).to eq(0)
      expect(page).to have_content("Accreditation added")
      expect(page).to have_content("Accreditation 1234")

      provider.reload
      expect(provider.accreditation_status).to eq("accredited")
    end

    scenario "SCITT provider creates accreditation" do
      scitt_provider = create(:provider, :scitt, :accredited)
      visit provider_accreditations_path(scitt_provider)

      click_link "Add accreditation"

      start_year = Date.current.year
      end_year = Date.current.year + 1
      fill_in "Accredited provider number", with: "5678"
      within_fieldset("Date accreditation starts") do
        fill_in "Day", with: "15"
        fill_in "Month", with: "6"
        fill_in "Year", with: start_year.to_s
      end
      within_fieldset("Date accreditation ends") do
        fill_in "Day", with: "31"
        fill_in "Month", with: "12"
        fill_in "Year", with: end_year.to_s
      end

      click_button "Continue"

      expect(page).to have_content("15 June #{start_year}")
      expect(page).to have_content("31 December #{end_year}")

      click_button "Save accreditation"

      expect(page).to have_content("Accreditation added")
      expect(page).to have_content("Accreditation 5678")
    end
  end

  context "with invalid data" do
    let(:provider) { create(:provider, :hei, :unaccredited) }

    scenario "missing accreditation number" do
      visit new_accreditation_path(provider_id: provider.id)

      start_year = Date.current.year
      within_fieldset("Date accreditation starts") do
        fill_in "Day", with: "1"
        fill_in "Month", with: "1"
        fill_in "Year", with: start_year.to_s
      end

      click_button "Continue"

      expect(page).to have_error_summary("Enter an accredited provider number")
      expect(TemporaryRecord.count).to eq(0)
    end

    scenario "missing start date" do
      visit new_accreditation_path(provider_id: provider.id)

      fill_in "Accredited provider number", with: "1234"

      click_button "Continue"

      expect(page).to have_error_summary("Enter date accreditation starts")
      expect(TemporaryRecord.count).to eq(0)
    end

    scenario "invalid number format for HEI" do
      visit new_accreditation_path(provider_id: provider.id)

      start_year = Date.current.year
      fill_in "Accredited provider number", with: "5234"
      within_fieldset("Date accreditation starts") do
        fill_in "Day", with: "1"
        fill_in "Month", with: "1"
        fill_in "Year", with: start_year.to_s
      end

      click_button "Continue"

      expect(page).to have_error_summary("Enter a valid accredited provider number - it must be 4 digits starting with a 1, like 1234")
      expect(TemporaryRecord.count).to eq(0)
    end

    scenario "invalid number format for SCITT" do
      scitt_provider = create(:provider, :scitt, :accredited)
      visit new_accreditation_path(provider_id: scitt_provider.id)

      start_year = Date.current.year
      fill_in "Accredited provider number", with: "1678"
      within_fieldset("Date accreditation starts") do
        fill_in "Day", with: "1"
        fill_in "Month", with: "1"
        fill_in "Year", with: start_year.to_s
      end

      click_button "Continue"

      expect(page).to have_error_summary("Enter a valid accredited provider number - it must be 4 digits starting with a 5, like 5234")
      expect(TemporaryRecord.count).to eq(0)
    end
  end

  context "check answers flow" do
    let(:provider) { create(:provider, :hei, :unaccredited) }

    scenario "can change values and resubmit" do
      visit new_accreditation_path(provider_id: provider.id)

      start_year = Date.current.year
      fill_in "Accredited provider number", with: "1234"
      within_fieldset("Date accreditation starts") do
        fill_in "Day", with: "1"
        fill_in "Month", with: "1"
        fill_in "Year", with: start_year.to_s
      end

      click_button "Continue"

      expect(page).to have_content("Check your answers")
      expect(page).to have_content("1234")

      click_link "Change", match: :first

      expect(page).to have_field("Accredited provider number", with: "1234")

      fill_in "Accredited provider number", with: "1999"

      click_button "Continue"

      expect(page).to have_content("1999")

      click_button "Save accreditation"

      expect(page).to have_content("Accreditation added")
      expect(page).to have_content("Accreditation 1999")
    end

    scenario "can cancel and return to index" do
      visit new_accreditation_path(provider_id: provider.id)

      fill_in "Accredited provider number", with: "1234"

      click_link "Cancel"

      expect(page).to have_current_path(provider_accreditations_path(provider))
      expect(TemporaryRecord.count).to eq(0)
    end
  end
end
