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
      expect(page).to have_link("Enter end date")
      expect(page).to have_content("Status")
      expect(page).to have_content("Active")
    end
  end

  scenario "does not offer edit or end actions when the accredited provider is archived" do
    provider.update!(archived_at: Time.zone.now)

    visit provider_partnerships_path(provider)

    within(".govuk-summary-card", text: partner.operating_name) do
      expect(page).to have_content("Recruitment")
      expect(page).not_to have_link("Change")
      expect(page).not_to have_link("End partnership")
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

  scenario "ends a partnership from the card" do
    visit provider_partnerships_path(provider)

    within(".govuk-summary-card", text: partner.operating_name) do
      click_link "End partnership"
    end

    expect(page).to have_content("End partnership with #{partner.operating_name}?")
    click_button "End partnership"

    expect(page).to have_content("Partnership with #{partner.operating_name} ended")
    expect(page).not_to have_css(".govuk-summary-card", text: partner.operating_name)
    expect(page).to have_content("View historic partnerships (1)")

    expect(partnership.reload).to be_kept
  end

  scenario "shows a scheduled partnership" do
    partnership.update!(duration: (Time.zone.today + 1.month)..)

    visit provider_partnerships_path(provider)

    within(".govuk-summary-card", text: partner.operating_name) do
      expect(page).to have_content("Scheduled")
      expect(page).to have_link("Delete")
      expect(page).not_to have_link("End partnership")
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

    expect(page).to have_content("Are you sure you want to change the partnership types?")
    expect(page).to have_content("Changing these partnership types will end the current partnership today, " \
                                 "#{Time.zone.today.to_fs(:govuk)}")
    click_button "Change"

    expect(page).to have_content("Check your answers")
    expect(page).to have_content("Training and Delivery")

    click_button "Save partnership"

    expect(page).to have_content("Partnership with #{partner.operating_name} updated")
    expect(page).to have_content("Training and Delivery")

    replacement = Partnership.kept
      .where(provider: partner, accredited_provider: provider)
      .where.not(id: partnership.id)
      .first

    expect(replacement.partnership_types.kept.map(&:partnership_type))
      .to eq([PartnershipTypeEnum::TRAINING_AND_DELIVERY])
    expect(replacement.duration.begin).to eq(Time.zone.today)

    expect(partnership.reload.duration.end).to eq(Time.zone.today)
    expect(partnership.partnership_types.kept.map(&:partnership_type))
      .to eq([PartnershipTypeEnum::RECRUITMENT])
  end
end
