require "rails_helper"

RSpec.describe "Editing partnership", type: :feature do
  before do
    given_i_am_an_authenticated_user
  end

  context "when editing an existing partnership" do
    let(:accredited_provider) { create(:provider, :accredited) }
    let(:training_partner) { create(:provider, :hei, :unaccredited, operating_name: "Test Training Partner") }
    let(:current_year) { Date.current.year }
    let!(:academic_cycle_current) do
      create(:academic_cycle, duration: Date.new(current_year, 8, 1)...Date.new(current_year + 1, 7, 31))
    end
    let!(:academic_cycle_next) do
      create(:academic_cycle, duration: Date.new(current_year + 1, 8, 1)...Date.new(current_year + 2, 7, 31))
    end
    let!(:partnership) do
      # Build without default academic cycle from factory callback
      p = Partnership.create!(
        provider: training_partner,
        accredited_provider: accredited_provider,
        duration: Date.new(current_year, 1, 1)..
      )
      p.academic_cycles << academic_cycle_current
      p
    end

    scenario "successfully edits partnership dates and academic years" do
      visit provider_partnerships_path(accredited_provider)

      expect(page).to have_content("Partnerships")
      expect(page).to have_content(training_partner.operating_name)

      within(".govuk-summary-card", text: training_partner.operating_name) do
        click_link "Change"
      end

      expect(page).to have_content("Partnership dates")
      expect(page).to have_content(accredited_provider.operating_name)
      expect(page).not_to have_content("Add partnership")

      fill_in_new_dates
      click_button "Continue"

      expect(page).to have_content("Academic year")

      check display_academic_year(academic_cycle_current)
      check display_academic_year(academic_cycle_next)
      click_button "Continue"

      expect(page).to have_content("Check your answers")
      expect(page).to have_content(accredited_provider.operating_name)
      expect(page).to have_content(training_partner.operating_name)

      click_button "Save partnership"

      expect(page).to have_content("Partnership updated")
      expect(page).to have_current_path(provider_partnerships_path(accredited_provider))

      partnership.reload
      expect(partnership.academic_cycles).to include(academic_cycle_current, academic_cycle_next)
    end

    scenario "can change dates from check your answers page" do
      visit provider_partnerships_path(accredited_provider)

      within(".govuk-summary-card", text: training_partner.operating_name) do
        click_link "Change"
      end

      fill_in_new_dates
      click_button "Continue"

      check display_academic_year(academic_cycle_current)
      click_button "Continue"

      expect(page).to have_content("Check your answers")

      click_link "Change", match: :first

      expect(page).to have_content("Partnership dates")
      within_fieldset("Partnership start date") do
        expect(find_field("Day").value).to eq("15")
      end

      fill_in_different_dates
      click_button "Continue"

      expect(page).to have_content("Academic year")

      check display_academic_year(academic_cycle_current)
      click_button "Continue"

      expect(page).to have_content("Check your answers")

      click_button "Save partnership"

      expect(page).to have_content("Partnership updated")
    end

    scenario "partner cannot be changed in edit flow" do
      visit provider_partnerships_path(accredited_provider)

      within(".govuk-summary-card", text: training_partner.operating_name) do
        click_link "Change"
      end

      fill_in_new_dates
      click_button "Continue"

      check display_academic_year(academic_cycle_current)
      click_button "Continue"

      expect(page).to have_content("Check your answers")
      expect(page).not_to have_link("Change", href: /find/)

      within("dd", text: accredited_provider.operating_name) do
        expect(page).not_to have_link("Change")
      end
    end
  end

  context "with validation errors" do
    let(:provider) { create(:provider, :accredited) }
    let(:partner) { create(:provider, :hei, :unaccredited) }
    let(:current_year) { Date.current.year }
    let!(:academic_cycle) do
      create(:academic_cycle, duration: Date.new(current_year, 8, 1)...Date.new(current_year + 1, 7, 31))
    end
    let!(:partnership) do
      p = Partnership.create!(
        provider: partner,
        accredited_provider: provider,
        duration: Date.new(current_year, 1, 1)..
      )
      p.academic_cycles << academic_cycle
      p
    end

    scenario "shows error when start date is cleared" do
      visit provider_edit_partnership_dates_path(partnership, provider_id: provider.id)

      within_fieldset("Partnership start date") do
        fill_in "Day", with: ""
        fill_in "Month", with: ""
        fill_in "Year", with: ""
      end

      click_button "Continue"

      expect(page).to have_content("Error")
      expect(page).to have_content("Enter date the partnership started")
    end

    scenario "shows error when no academic year selected" do
      visit provider_edit_partnership_dates_path(partnership, provider_id: provider.id)

      fill_in_new_dates
      click_button "Continue"

      # Uncheck pre-selected academic years
      uncheck display_academic_year(academic_cycle)

      click_button "Continue"

      expect(page).to have_content("Error")
      expect(page).to have_content("Select academic year")
    end
  end

  context "cancellation flow" do
    let(:provider) { create(:provider, :accredited) }
    let(:partner) { create(:provider, :hei, :unaccredited) }
    let(:current_year) { Date.current.year }
    let!(:academic_cycle) do
      create(:academic_cycle, duration: Date.new(current_year, 8, 1)...Date.new(current_year + 1, 7, 31))
    end
    let!(:partnership) do
      p = Partnership.create!(
        provider: partner,
        accredited_provider: provider,
        duration: Date.new(current_year, 1, 1)..
      )
      p.academic_cycles << academic_cycle
      p
    end

    scenario "can cancel and return to partnerships list" do
      visit provider_edit_partnership_dates_path(partnership, provider_id: provider.id)

      fill_in_new_dates

      click_link "Cancel"

      expect(page).to have_current_path(provider_partnerships_path(provider))
    end
  end

private

  def fill_in_new_dates
    current_year = Date.current.year
    within_fieldset("Partnership start date") do
      fill_in "Day", with: "15"
      fill_in "Month", with: "8"
      fill_in "Year", with: current_year.to_s
    end
  end

  def fill_in_different_dates
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
