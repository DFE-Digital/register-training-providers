module AddressJourney
  class SelectPresenter
    include Rails.application.routes.url_helpers

    attr_reader :results, :postcode, :building_name_or_number, :provider, :back_path, :form_url, :change_search_path,
                :manual_entry_path, :cancel_path, :page_subtitle, :page_caption

    def initialize(results:, postcode:, building_name_or_number:, provider:, back_path:, form_url:,
                   change_search_path:, manual_entry_path:, cancel_path:, page_subtitle:, page_caption:)
      @results = results
      @postcode = postcode
      @building_name_or_number = building_name_or_number
      @provider = provider
      @back_path = back_path
      @form_url = form_url
      @change_search_path = change_search_path
      @manual_entry_path = manual_entry_path
      @cancel_path = cancel_path
      @page_subtitle = page_subtitle
      @page_caption = page_caption
    end

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

    def formatted_address(address)
      [
        address["address_line_1"],
        address["address_line_2"],
        address["town_or_city"],
        address["postcode"]
      ].compact_blank.join(", ")
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
