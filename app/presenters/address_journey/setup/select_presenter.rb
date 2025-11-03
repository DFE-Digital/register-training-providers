module AddressJourney
  module Setup
    class SelectPresenter < BasePresenter
      attr_reader :results, :find_form, :error

      def initialize(results:, find_form:, provider:, error: nil)
        super(provider:)
        @results = results
        @find_form = find_form
        @error = error
      end

      def form_url
        providers_setup_addresses_select_path
      end

      def page_title
        if results.empty?
          no_results_title
        elsif results.size == 1
          single_result_title
        else
          multiple_results_title
        end
      end

      def back_path
        providers_setup_addresses_find_path
      end

      def change_search_path
        providers_setup_addresses_find_path
      end

      def search_term
        if find_form&.building_name_or_number.present?
          "'#{find_form.building_name_or_number}'"
        else
          "'#{find_form&.postcode}'"
        end
      end

      def submit_button_text
        results.size == 1 ? "Confirm address" : "Continue"
      end

    private

      def no_results_title
        if find_form&.building_name_or_number.present?
          "No addresses found for '#{find_form.postcode}' and '#{find_form.building_name_or_number}'"
        else
          "No addresses found for '#{find_form&.postcode}'"
        end
      end

      def single_result_title
        "1 address found for #{search_term}"
      end

      def multiple_results_title
        "#{results.size} addresses found for #{search_term}"
      end
    end
  end
end
