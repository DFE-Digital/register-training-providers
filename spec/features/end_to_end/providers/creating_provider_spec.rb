require "rails_helper"

RSpec.feature "Add Provider" do
  shared_examples "adding a provider with accreditation status" do |accreditation_status|
    scenario "User can add a new provider with accreditation status: #{accreditation_status}" do
      given_i_am_an_authenticated_user
      when_i_navigate_to_the_add_provider_page
      and_i_fill_out_the_provider_form_with_valid_details(accreditation_status:)
      and_i_checked_my_answers
      then_i_should_be_redirected_to_the_provider_list_page
      and_i_should_see_a_success_message
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
    end

    def and_i_fill_in_the_provider_details(provider_details:, select_provider_type:)
      expect(TemporaryRecord.count).to eq(2)
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
      expect(TemporaryRecord.count).to eq(3)
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
      expect(TemporaryRecord.count).to eq(1)

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
      expect(TemporaryRecord.count).to eq(0)

      and_i_am_taken_to("/providers/new")

      and_i_can_see_the_title("Is the provider accredited? - Add provider - Register of training providers - GOV.UK")
      and_i_do_not_see_error_summary

      and_i_click_on("Continue")

      and_i_can_see_the_error_summary("Select if the provider is accredited")
      and_i_can_see_the_title("Error: Is the provider accredited? - Add provider - Register of training providers - GOV.UK")

      # Debug what's actually on the page
      puts "Page title: #{page.title}"
      puts "Page body includes 'accredited': #{page.body.include?('accredited')}"
      puts "All form elements: #{all('input, select, textarea').map { |el| "#{el.tag_name}[#{el[:type]}]: #{el[:name]}=#{el[:value]}" }}"
      puts "Available radio buttons: #{all('input[type="radio"]').map(&:value)}"
      puts "Looking for: #{select_if_the_provider_is_accredited}"

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
      and_the_temporary_record_should_be_cleared
      expect(Provider.count).to eq(1)
    end

    def and_the_temporary_record_should_be_cleared
      expect(TemporaryRecord.count).to eq(0)
    end

    def and_i_should_see_a_success_message
      expect(page).to have_notification_banner("Success", "Provider added")
    end

    def and_i_checked_my_answers
      # Accredited providers will have 4 temp records, unaccredited will have 3
      expected_count = @provider_details_to_use.accredited? ? 4 : 3
      expect(TemporaryRecord.count).to eq(expected_count)
      and_i_am_taken_to("/providers/check/new")
      and_i_can_see_the_title("Check your answers - Add provider - Register of training providers - GOV.UK")
      when_i_click_on("Save provider")
    end

    def then_i_see_the_success_message
      expect(page).to have_notification_banner("Success", "Support user added")
    end

    def and_i_do_not_see_error_summary
      expect(page).not_to have_error_summary
    end
  end

  include_examples "adding a provider with accreditation status", :accredited
  include_examples "adding a provider with accreditation status", :unaccredited
end
