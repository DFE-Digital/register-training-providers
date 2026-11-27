module AccreditationJourney
  class SessionManager
    attr_reader :context

    def initialize(session, context: nil)
      @session = session
      @context = context
    end

    def store_accreditation(accreditation_attributes)
      journey_data[:accreditation] = accreditation_attributes
    end

    def add_attributes(new_attributes)
      new_attributes.each do |k, v|
        journey_data[:accreditation][k] = v
      end
    end

    def load_accreditation
      accreditation_data = journey_data[:accreditation]
      accreditation_data&.with_indifferent_access
    end

    def clear!
      # For setup context, only clear accreditation-specific keys, not the entire provider_creation session
      if @context == :setup
        journey_data.delete(:accreditation)
      else
        @session.delete(session_key)
      end
    end

  private

    def journey_data
      @session[session_key] ||= {}
    end

    def session_key
      return :imported_data_accreditation_creation if @context == :imported_data

      @context == :setup ? :provider_creation : :accreditation_creation
    end
  end
end
