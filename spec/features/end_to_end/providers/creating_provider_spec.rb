require "rails_helper"

RSpec.feature "Add Provider" do
  shared_examples "adding a provider with accreditation status" do |accreditation_status|
    let(:address_line_1) { Faker::Address.street_address }
    let(:address_line_2) { Faker::Address.secondary_address }
    let(:town_or_city) { Faker::Address.city }
    let(:county) { Faker::Address.state }
    let(:postcode) { Faker::Address.postcode }

    scenario "User can add a new provider with accreditation status: #{accreditation_status}" do
      given_i_am_an_authenticated_user
      when_i_navigate_to_the_add_provider_page
      and_i_fill_out_the_provider_form_with_valid_details(accreditation_status:)
      and_i_am_on_the_check_answers_page
      then_the_address_should_be_displayed_on_check_answers
      when_i_save_the_provider
      then_i_should_be_redirected_to_the_provider_list_page
      and_i_should_see_a_success_message
      and_the_address_should_be_saved_to_the_provider
    end

    def when_i_navigate_to_the_add_provider_page
      visit providers_path
      click_on("Add provider")
    end

    def and_i_fill_out_the_provider_form_with_valid_details(accreditation_status:)
      info = get_provider_information_for_the_forms(accreditation_status:)

      and_i_answer_the_accreditation_question(select_if_the_provider_is_accredited: info[:select_if_the_provider_is_accredited])

      and_i_select_the_provider_type(select_provider_type: info[:select_provider_type])

      and_i_fill_in_the_provider_details(provider_details: info[:provider_details], select_provider_type: info[:select_provider_type])

      if accreditation_status == :accredited
        and_i_fill_in_the_accreditation_details
      end

      and_i_fill_in_the_address_details
    end

    def and_i_fill_in_the_provider_details(provider_details:, select_provider_type:)
      and_i_am_taken_to("/providers/new/details")
      and_i_can_see_the_title("Provider details - Add provider - Register of training providers - GOV.UK")
      and_i_do_not_see_error_summary

      and_i_click_on("Continue")

      error_messages = provider_details_error_messages(select_provider_type:)
      and_i_can_see_the_error_summary(*error_messages)
      and_i_can_see_the_title("Error: Provider details - Add provider - Register of training providers - GOV.UK")

      and_i_fill_in_the_provider_details_form_correctly(provider_details:)

      and_i_click_on("Continue")
    end

    def and_i_fill_in_the_accreditation_details
      and_i_am_taken_to("/providers/new/accreditation")
      and_i_can_see_the_title("Accreditation details - Register of training providers - GOV.UK")
      and_i_do_not_see_error_summary

      and_i_click_on("Continue")

      and_i_can_see_the_error_summary("Enter an accredited provider number", "Enter date accreditation starts")
      and_i_can_see_the_title("Error: Accreditation details - Register of training providers - GOV.UK")

      start_year = Date.current.year
      fill_in "Accredited provider number", with: "1234"
      within_fieldset("Date accreditation starts") do
        fill_in "Day", with: "1"
        fill_in "Month", with: "1"
        fill_in "Year", with: start_year.to_s
      end

      and_i_click_on("Continue")
    end

    def and_i_fill_in_the_address_details
      and_i_am_taken_to("/providers/new/addresses")
      and_i_can_see_the_title("Add address - Add provider - Register of training providers - GOV.UK")
      and_i_do_not_see_error_summary

      and_i_click_on("Continue")

      and_i_can_see_the_error_summary(
        "Enter address line 1, typically the building and street",
        "Enter town or city",
        "Enter postcode"
      )
      and_i_can_see_the_title("Error: Add address - Add provider - Register of training providers - GOV.UK")

      fill_in "Address line 1", with: address_line_1
      fill_in "Address line 2 (optional)", with: address_line_2
      fill_in "Town or city", with: town_or_city
      fill_in "County (optional)", with: county
      fill_in "Postcode", with: postcode

      and_i_click_on("Continue")
    end

    def and_i_fill_in_the_provider_details_form_correctly(provider_details:)
      provider_details.each do |label, value|
        page.fill_in label, with: value
      end
    end

    def provider_details_error_messages(select_provider_type:)
      errors = ["Enter operating name", "Enter UK provider reference number (UKPRN)", "Enter provider code"]

      errors += ["Enter unique reference number (URN)"] if ["School", "School-centred initial teacher training (SCITT)"].include?(select_provider_type)

      errors
    end

    def get_provider_information_for_the_forms(accreditation_status:)
      @provider_details_to_use = build(:provider, accreditation_status)

      select_if_the_provider_is_accredited = {
        accredited: "Yes",
        unaccredited: "No",
      }[@provider_details_to_use.accreditation_status.to_sym]

      select_provider_type = {
        hei: "Higher education institution (HEI)",
        scitt: "School-centred initial teacher training (SCITT)",
        school: "School",
        other: "Other",
      }[@provider_details_to_use.provider_type.to_sym]

      provider_details = [
        ["Operating name", @provider_details_to_use.operating_name],
        ["Legal name (optional)", @provider_details_to_use.legal_name],
        ["UK provider reference number (UKPRN)", @provider_details_to_use.ukprn],
        ["Unique reference number (URN)#{" (optional)" unless @provider_details_to_use.requires_urn?}", @provider_details_to_use.urn],
        ["Provider code", @provider_details_to_use.code],
      ]

      {
        select_if_the_provider_is_accredited:,
        select_provider_type:,
        provider_details:
      }
    end

    def and_i_select_the_provider_type(select_provider_type:)
      and_i_am_taken_to("/providers/new/type")
      and_i_can_see_the_title("Provider type - Add provider - Register of training providers - GOV.UK")
      and_i_do_not_see_error_summary

      and_i_click_on("Continue")

      and_i_can_see_the_error_summary("Select provider type")
      and_i_can_see_the_title("Error: Provider type - Add provider - Register of training providers - GOV.UK")

      and_i_choose(select_provider_type)

      and_i_click_on("Continue")
    end

    def and_i_answer_the_accreditation_question(select_if_the_provider_is_accredited:)
      and_i_am_taken_to("/providers/new")

      and_i_can_see_the_title("Is the provider accredited? - Add provider - Register of training providers - GOV.UK")
      and_i_do_not_see_error_summary

      and_i_click_on("Continue")

      and_i_can_see_the_error_summary("Select if the provider is accredited")
      and_i_can_see_the_title("Error: Is the provider accredited? - Add provider - Register of training providers - GOV.UK")

      and_i_choose(select_if_the_provider_is_accredited)

      and_i_click_on("Continue")
    end

    alias_method :and_i_choose, :choose

    def and_i_can_see_the_error_summary(*messages)
      expect(page).to have_error_summary(*messages)
    end

    def and_i_can_see_the_title(title)
      expect(page).to have_title(title)
    end

    def then_i_should_be_redirected_to_the_provider_list_page
      and_i_am_taken_to("/providers")
      expect(Provider.count).to eq(1)
    end

    def and_i_should_see_a_success_message
      expect(page).to have_notification_banner("Success", "Provider added")
    end

    def and_i_am_on_the_check_answers_page
      and_i_am_taken_to("/providers/check/new")
      and_i_can_see_the_title("Check your answers - Add provider - Register of training providers - GOV.UK")
    end

    def when_i_save_the_provider
      when_i_click_on("Save provider")
    end

    def then_i_see_the_success_message
      expect(page).to have_notification_banner("Success", "Support user added")
    end

    def and_i_do_not_see_error_summary
      expect(page).not_to have_error_summary
    end

    def then_the_address_should_be_displayed_on_check_answers
      expect(page).to have_content("Address")
      expect(page).to have_content(address_line_1)
      expect(page).to have_content(address_line_2)
      expect(page).to have_content(town_or_city)
      expect(page).to have_content(county)
      expect(page).to have_content(postcode)
    end

    def and_the_address_should_be_saved_to_the_provider
      provider = Provider.last
      expect(provider.addresses.count).to eq(1)

      address = provider.addresses.first
      expect(address.address_line_1).to eq(address_line_1)
      expect(address.address_line_2).to eq(address_line_2)
      expect(address.town_or_city).to eq(town_or_city)
      expect(address.county).to eq(county)
      expect(address.postcode).to eq(postcode)
    end
  end

  include_examples "adding a provider with accreditation status", :accredited
  include_examples "adding a provider with accreditation status", :unaccredited
end
