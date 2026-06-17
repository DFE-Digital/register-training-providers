module ProviderCreation
  class SessionManager
    def initialize(session)
      @session = session
    end

    def store_provider(provider_attributes)
      data[:provider] = provider_attributes
    end

    def load_provider
      provider_data = data[:provider]
      return nil unless provider_data

      Provider.new(provider_data)
    end

    def store_accreditation(accreditation_attributes)
      data[:accreditation] = accreditation_attributes
    end

    def load_accreditation
      data[:accreditation]
    end

    def store_onboarding(attributes)
      data[:onboarding] = attributes
    end

    def load_onboarding
      data[:onboarding]
    end

    def store_first_become_active(attributes)
      data[:first_become_active] = attributes
    end

    def load_first_become_active
      data[:first_become_active]
    end

    def store_is_provider_accredited(attributes)
      data[:is_provider_accredited] = attributes
    end

    def load_is_provider_accredited
      data[:is_provider_accredited]
    end

    def store_provider_type(attributes)
      data[:provider_type] = attributes
    end

    def load_provider_type
      data[:provider_type]
    end

    def clear!
      @session.delete(:provider_creation)
    end

    def current_step
      data[:current_step] || :onboarding
    end

    def current_step=(step)
      data[:current_step] = step
    end

  private

    def data
      @session[:provider_creation] ||= {}
    end
  end
end
