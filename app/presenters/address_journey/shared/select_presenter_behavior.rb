module AddressJourney
  module Shared
    module SelectPresenterBehavior
      def page_title
        if results.empty?
          no_results_title
        else
          results_title
        end
      end

      def submit_button_text
        "Continue"
      end

    private

      def no_results_title
        "No addresses found for #{formatted_search_terms}"
      end

      def results_title
        "#{results.size} #{'address'.pluralize(results.size)} found for #{formatted_search_terms}"
      end

      def formatted_search_terms
        search_terms = ["'#{postcode}'"]
        search_terms << "'#{building_name_or_number}'" if building_name_or_number.present?
        search_terms.join(" and ")
      end
    end
  end
end
