module PartnershipJourney
  class SessionManager
    def initialize(session)
      @session = session
    end

    def store_partnership(partnership_attributes)
      journey_data[:partnership] = partnership_attributes
    end

    def load_partnership
      partnership_data = journey_data[:partnership]
      partnership_data&.with_indifferent_access
    end

    def clear!
      journey_data.delete(:partnership)
    end

  private

    def journey_data
      @session[:partnership] ||= {}
    end
  end
end
