require "rails_helper"

RSpec.describe "Viewing partnership cards", type: :feature do
  before { given_i_am_an_authenticated_user }

  let(:provider) { create(:provider, :accredited) }
  let(:partner) { create(:provider, :hei_without_accreditation, operating_name: "Partner College") }
  let!(:academic_year) { create(:academic_year) }
  let!(:partnership) do
    create(:partnership,
           accredited_provider: provider,
           provider: partner,
           duration: (Time.zone.today - 1.month)..)
  end

  scenario "shows the partnership types, dates and status" do
    visit provider_partnerships_path(provider)

    within(".govuk-summary-card", text: partner.operating_name) do
      expect(page).to have_content("Partnership types")
      expect(page).to have_content("Recruitment")
      expect(page).to have_content("Starts")
      expect(page).to have_content("Ends")
      expect(page).to have_content("No end date")
      expect(page).to have_content("Status")
      expect(page).to have_content("Active")
    end
  end

  scenario "does not list an ended partnership as current" do
    partnership.update!(duration: Date.new(2024, 9, 1)...Date.new(2025, 7, 31))

    visit provider_partnerships_path(provider)

    expect(page).not_to have_content(partner.operating_name)
    expect(page).to have_content("View historic partnerships (1)")
  end

  scenario "links to the historic partnerships" do
    partnership.update!(duration: Date.new(2024, 9, 1)...Date.new(2025, 7, 31))

    visit provider_partnerships_path(provider)

    expect(page).to have_content("Current partnerships")
    click_link "View historic partnerships (1)"

    expect(page).to have_content("Historic partnerships")
    expect(page).to have_content("Previous partnerships for this provider.")
    expect(page).to have_content(partner.operating_name)
    expect(page).to have_content("Recruitment")
  end

  scenario "shows a scheduled partnership" do
    partnership.update!(duration: (Time.zone.today + 1.month)..)

    visit provider_partnerships_path(provider)

    within(".govuk-summary-card", text: partner.operating_name) do
      expect(page).to have_content("Scheduled")
    end
  end

  scenario "changes the partnership types from the card" do
    visit provider_partnerships_path(provider)

    within(".govuk-summary-list__row", text: "Partnership types") do
      click_link "Change"
    end

    expect(page).to have_content("Select partnership types")

    uncheck "Recruitment"
    check "Training and Delivery"
    click_button "Continue"

    expect(page).to have_content("Check your answers")
    expect(page).to have_content("Training and Delivery")

    click_button "Save partnership"

    expect(page).to have_content("Partnership with #{partner.operating_name} updated")

    partnership.reload
    expect(partnership.partnership_types.kept.map(&:partnership_type))
      .to eq([PartnershipTypeEnum::TRAINING_AND_DELIVERY])
    expect(partnership.partnership_types.count).to eq(2)
  end
end
