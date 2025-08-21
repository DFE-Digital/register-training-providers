require "rails_helper"

RSpec.describe "Viewing provider accreditations", type: :feature do
  let(:provider) { create(:provider, :accredited) }

  before do
    given_i_am_an_authenticated_user
  end

  context "when provider has accreditations" do
    let!(:current_accreditation) do
      create(:accreditation,
             provider: provider,
             number: "1234",
             start_date: 1.year.ago.to_date,
             end_date: 1.year.from_now.to_date)
    end

    let!(:expired_accreditation) do
      create(:accreditation,
             provider: provider,
             number: "5123",
             start_date: 4.years.ago.to_date,
             end_date: 2.years.ago.to_date)
    end

    scenario "viewing accreditations from provider details page" do
      visit provider_path(provider)

      expect(page).to have_content(provider.operating_name)

      click_link "Accreditations"

      expect(page).to have_content("Accreditations")

      within first(".govuk-summary-card") do
        expect(page).to have_content("Accreditation #{expired_accreditation.number}")
        expect(page).to have_content(expired_accreditation.start_date.to_fs(:govuk))
        expect(page).to have_content(expired_accreditation.end_date.to_fs(:govuk))
      end

      within all(".govuk-summary-card")[1] do
        expect(page).to have_content("Accreditation #{current_accreditation.number}")
        expect(page).to have_content(current_accreditation.start_date.to_fs(:govuk))
        expect(page).to have_content(current_accreditation.end_date.to_fs(:govuk))
      end
    end

    scenario "navigation works correctly" do
      visit provider_path(provider)

      expect(page).to have_css(".app-secondary-navigation__item--active a", text: "Provider details")
      expect(page).to have_content("Provider details")

      click_link "Accreditations"

      expect(page).to have_css(".app-secondary-navigation__item--active a", text: "Accreditations")
      expect(page).to have_content("1234")
    end
  end

  context "when provider has no accreditations" do
    scenario "shows empty state" do
      visit provider_path(provider)

      click_link "Accreditations"

      expect(page).to have_content("This provider has no accreditations")
      expect(page).to have_link("Add accreditation")
    end
  end
end
