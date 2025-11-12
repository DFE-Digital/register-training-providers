module AddressJourney
  class SessionManager
    attr_reader :context

    def initialize(session, context:)
      @session = session
      @context = context
    end

    def store_search(postcode:, building_name_or_number:, results:)
      journey_data[:search] = {
        postcode: postcode,
        building_name_or_number: building_name_or_number,
        results: results,
        searched_at: Time.current
      }
    end

    def load_search
      journey_data[:search]
    end

    def store_address(address_attributes)
      journey_data[:address] = address_attributes
    end

    def load_address
      journey_data[:address]
    end

    def clear!
      # For setup context, only clear address-specific keys, not the entire provider_creation session
      if @context == :setup
        journey_data.delete(:search)
        journey_data.delete(:address)
        journey_data.delete(:from_check)
      else
        @session.delete(session_key)
      end
    end

    def came_from_check?
      journey_data[:from_check] == true
    end

    def mark_from_check!
      journey_data[:from_check] = true
    end

    def clear_navigation_state!
      journey_data.delete(:from_check)
    end

    # Check if the stored address was entered manually (not from search)
    def manual_entry?
      address_data = load_address
      return false unless address_data

      address_data[:manual_entry] == true || address_data["manual_entry"] == true
    end

    # Check if search results are available
    def search_results_available?
      search_data = load_search
      search_data.present? && search_data[:results]&.any?
    end

  private

    def journey_data
      @session[session_key] ||= {}
    end

    def session_key
      @context == :setup ? :provider_creation : :address_creation
    end
  end
end
