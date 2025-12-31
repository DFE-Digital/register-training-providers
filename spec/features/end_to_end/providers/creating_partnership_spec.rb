require "rails_helper"

RSpec.describe "Creating partnership", type: :feature do
  before do
    given_i_am_an_authenticated_user
  end

  context "when accredited provider adds unaccredited partner" do
    let(:accredited_provider) { create(:provider, :accredited) }
    let!(:unaccredited_partner) { create(:provider, :hei, :unaccredited, operating_name: "Test Training Partner") }
    let!(:academic_cycle) { create(:academic_cycle) }

    scenario "successfully creates a partnership" do
      visit provider_partnerships_path(accredited_provider)

      expect(page).to have_content("Partnerships")

      within(".govuk-button-group") do
        click_link "Add partnership"
      end

      expect(page).to have_content("Enter training partner name")

      select unaccredited_partner.operating_name, from: "Search for a training partner"
      click_button "Continue"

      expect(page).to have_content("Partnership dates")

      fill_in_start_date
      click_button "Continue"

      expect(page).to have_content("Academic year")

      check display_academic_year(academic_cycle)
      click_button "Continue"

      expect(page).to have_content("Check your answers")
      expect(page).to have_content(accredited_provider.operating_name)
      expect(page).to have_content(unaccredited_partner.operating_name)

      click_button "Save partnership"

      expect(page).to have_content("Partnership added")
      expect(page).to have_current_path(provider_partnerships_path(accredited_provider))

      accredited_provider.reload
      expect(accredited_provider.partnerships.count).to eq(1)

      partnership = accredited_provider.partnerships.first
      expect(partnership.provider).to eq(unaccredited_partner)
      expect(partnership.accredited_provider).to eq(accredited_provider)
    end
  end

  context "when unaccredited provider adds accredited partner" do
    let(:unaccredited_provider) { create(:provider, :hei, :unaccredited) }
    let!(:accredited_partner) { create(:provider, :accredited, operating_name: "Accredited University") }
    let!(:academic_cycle) { create(:academic_cycle) }

    scenario "successfully creates a partnership" do
      visit provider_partnerships_path(unaccredited_provider)

      expect(page).to have_content("Partnerships")

      within(".govuk-button-group") do
        click_link "Add partnership"
      end

      select accredited_partner.operating_name, from: "Search for a training partner"
      click_button "Continue"

      fill_in_start_date
      click_button "Continue"

      check display_academic_year(academic_cycle)
      click_button "Continue"

      expect(page).to have_content("Check your answers")

      click_button "Save partnership"

      expect(page).to have_content("Partnership added")

      unaccredited_provider.reload
      expect(unaccredited_provider.partnerships.count).to eq(1)

      partnership = unaccredited_provider.partnerships.first
      expect(partnership.provider).to eq(unaccredited_provider)
      expect(partnership.accredited_provider).to eq(accredited_partner)
    end
  end

  context "with validation errors" do
    let(:provider) { create(:provider, :accredited) }
    let!(:partner) { create(:provider, :hei, :unaccredited) }
    let!(:academic_cycle) { create(:academic_cycle) }

    scenario "shows error when no partner selected" do
      visit provider_new_partnership_find_path(provider)

      click_button "Continue"

      expect(page).to have_content("Error")
      expect(page).to have_content("can't be blank")
    end

    scenario "shows error when no start date entered" do
      visit provider_new_partnership_find_path(provider)

      select partner.operating_name, from: "Search for a training partner"
      click_button "Continue"

      click_button "Continue"

      expect(page).to have_content("Error")
    end

    scenario "shows error when no academic year selected" do
      visit provider_new_partnership_find_path(provider)

      select partner.operating_name, from: "Search for a training partner"
      click_button "Continue"

      fill_in_start_date
      click_button "Continue"

      click_button "Continue"

      expect(page).to have_content("Error")
      expect(page).to have_content("can't be blank")
    end
  end

  context "cancellation flow" do
    let(:provider) { create(:provider, :accredited) }
    let!(:partner) { create(:provider, :hei, :unaccredited) }

    scenario "can cancel and return to partnerships" do
      visit provider_new_partnership_find_path(provider)

      select partner.operating_name, from: "Search for a training partner"

      click_link "Cancel"

      expect(page).to have_current_path(provider_partnerships_path(provider))
      expect(provider.partnerships.count).to eq(0)
    end
  end

private

  def fill_in_start_date
    current_year = Date.current.year
    within_fieldset("Partnership start date") do
      fill_in "Day", with: "1"
      fill_in "Month", with: "9"
      fill_in "Year", with: current_year.to_s
    end
  end

  def display_academic_year(academic_cycle)
    "#{academic_cycle.duration.begin.year} to #{academic_cycle.duration.end.year}"
  end
end

