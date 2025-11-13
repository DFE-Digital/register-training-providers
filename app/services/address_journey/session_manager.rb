module AddressJourney
  class SessionManager
    attr_reader :context

    def initialize(session, context:)
      @session = session
      @context = context
    end

    def store_search(postcode:, building_name_or_number:, results:)
      journey_data[:search] = {
        postcode:,
        building_name_or_number:,
        results:
      }
    end

    def load_search
      journey_data[:search]
    end

    def store_address(address_attributes)
      journey_data[:address] = address_attributes
    end

    def load_address
      address_data = journey_data[:address]
      address_data&.with_indifferent_access
    end

    def clear!
      # For setup context, only clear address-specific keys, not the entire provider_creation session
      if @context == :setup
        journey_data.delete(:search)
        journey_data.delete(:address)
      else
        @session.delete(session_key)
      end
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
