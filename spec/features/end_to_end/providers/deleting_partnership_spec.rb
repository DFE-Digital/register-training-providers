require "rails_helper"

RSpec.describe "Deleting partnership", type: :feature do
  before do
    given_i_am_an_authenticated_user
  end

  context "with an existing partnership" do
    let(:provider) { create(:provider, :unaccredited) }
    let(:accredited_provider) { create(:provider, :accredited) }
    let!(:partnership) do
      create(:partnership, provider:, accredited_provider:, duration: (Time.zone.today - 1.month)..)
    end

    scenario "deletes partnership for provider" do
      visit provider_partnerships_path(provider)

      expect(page).to have_content(provider.operating_name)
      expect(page).to have_content(accredited_provider.operating_name)
      expect(provider.partnerships.kept.count).to eq(1)

      click_link "Delete", match: :first

      expect(page).to have_content("Are you sure you want to delete the partnership with #{accredited_provider.operating_name}?")
      expect(page).to have_content("Delete partnership")

      expect(page).to have_content(
        "Deleting this partnership will permanently remove it from the provider record. " \
        "It may still be retained for audit purposes."
      )
      expect(page).to have_warning_text("You cannot undo this action.")

      expect(page).to have_link("Cancel", href: provider_partnerships_path(provider))

      click_button "Delete partnership"

      expect(current_path).to eq(provider_partnerships_path(provider))

      expect(page).to have_content("Partnership deleted")

      expect(page).not_to have_content(accredited_provider.operating_name)
      expect(page).to have_content("There are no current partnerships for #{provider.operating_name}")

      expect(provider.partnerships.kept.count).to eq(0)
      expect(provider.partnerships.count).to eq(1)
      expect(partnership.reload.discarded?).to be true
    end

    scenario "cancels deletion and returns to partnerships" do
      visit provider_partnerships_path(provider)

      click_link "Delete", match: :first

      expect(page).to have_content("Are you sure you want to delete the partnership with #{accredited_provider.operating_name}?")

      click_link "Cancel"

      expect(current_path).to eq(provider_partnerships_path(provider))

      expect(page).to have_content(accredited_provider.operating_name)
      expect(provider.partnerships.kept.count).to eq(1)
      expect(partnership.reload.discarded?).to be false
    end

    scenario "offers the end journey instead of deleting" do
      visit provider_partnerships_path(provider)
      click_link "Delete", match: :first

      expect(page).to have_content("Only delete a partnership if the record was created incorrectly.")
      expect(page).to have_link("End partnership",
                                href: provider_partnership_end_path(partnership, provider_id: provider.id))
    end
  end

  context "with a partnership that cannot be ended" do
    let(:provider) { create(:provider, :unaccredited) }
    let(:accredited_provider) { create(:provider, :accredited) }
    let!(:partnership) do
      create(:partnership, provider: provider, accredited_provider: accredited_provider,
                           duration: 1.month.from_now..)
    end

    scenario "does not offer the end journey from the delete page" do
      visit provider_partnership_delete_path(partnership, provider_id: provider.id)

      expect(page).to have_content("Are you sure you want to delete the partnership with #{accredited_provider.operating_name}?")
      expect(page).not_to have_content("Only delete a partnership if the record was created incorrectly.")
      expect(page).not_to have_link("End partnership")
      expect(page).to have_button("Delete partnership")
    end
  end

  context "with multiple partnerships" do
    let(:provider) { create(:provider, :unaccredited) }
    let(:accredited_provider) { create(:provider, :accredited) }
    let(:other_accredited_provider) { create(:provider, :accredited) }
    let!(:partnership1) do
      create(:partnership,
             provider:,
             accredited_provider:,)
    end

    let!(:partnership2) do
      create(:partnership,
             provider: provider,
             accredited_provider: other_accredited_provider,)
    end

    scenario "deletes one partnership while keeping others" do
      visit provider_partnerships_path(provider)

      expect(page).to have_content(provider.operating_name)
      expect(page).to have_content(accredited_provider.operating_name)
      expect(page).to have_content(other_accredited_provider.operating_name)
      expect(provider.partnerships.kept.count).to eq(2)

      within(".govuk-summary-card", text: accredited_provider.operating_name) do
        click_link "Delete"
      end

      expect(page).to have_content("Are you sure you want to delete the partnership with #{accredited_provider.operating_name}?")
      expect(page).to have_content("Delete partnership")

      click_button "Delete partnership"

      expect(current_path).to eq(provider_partnerships_path(provider))

      expect(page).to have_content("Partnership deleted")

      expect(page).not_to have_content(accredited_provider.operating_name)
      expect(page).to have_content(other_accredited_provider.operating_name)
      expect(page).to have_content("Current partnerships")
      expect(page).not_to have_content("View historic partnerships")

      expect(provider.partnerships.kept.count).to eq(1)
      expect(provider.partnerships.count).to eq(2)
      expect(partnership1.reload.discarded?).to be true
      expect(partnership2.reload.discarded?).to be false
    end
  end
end
