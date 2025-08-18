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
             number: "ACC123",
             start_date: Date.new(2023, 1, 1),
             end_date: Date.new(2025, 12, 31))
    end
    
    let!(:expired_accreditation) do
      create(:accreditation,
             provider: provider,
             number: "ACC456", 
             start_date: Date.new(2020, 1, 1),
             end_date: Date.new(2022, 12, 31))
    end

    scenario "viewing accreditations from provider details page" do
      visit provider_path(provider)
      
      expect(page).to have_content(provider.operating_name)
      expect(page).to have_link("Accreditations")
      
      click_link "Accreditations"
      
      expect(page).to have_content("Accreditations")

      within first(".govuk-summary-card") do
        expect(page).to have_content("Accreditation ACC456")
        expect(page).to have_content("1 January 2020")
        expect(page).to have_content("31 December 2022")
      end

      within all(".govuk-summary-card")[1] do
        expect(page).to have_content("Accreditation ACC123")
        expect(page).to have_content("1 January 2023")
        expect(page).to have_content("31 December 2025")
      end
    end

    scenario "navigation works correctly" do
      visit provider_path(provider)
      
      expect(page).to have_css(".app-secondary-navigation__item--active a", text: "Provider details")
      expect(page).to have_content("Provider details")
      
      click_link "Accreditations"
      
      expect(page).to have_css(".app-secondary-navigation__item--active a", text: "Accreditations")
      expect(page).to have_content("ACC123")
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
