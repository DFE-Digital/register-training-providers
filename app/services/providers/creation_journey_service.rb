module Providers
  class CreationJourneyService
    def initialize(current_step:, provider:, goto_param: nil)
      @current_step = current_step.to_sym
      @provider = provider
      @goto_param = goto_param
    end

    def next_path
      return url_helpers.new_provider_confirm_path if from_check_page?

      case @current_step
      when :onboarding
        url_helpers.new_provider_type_path
      when :type
        url_helpers.new_provider_details_path
      when :details
        if @provider.accredited?
          url_helpers.new_provider_accreditation_path
        else
          url_helpers.providers_setup_addresses_address_path
        end
      when :accreditation
        url_helpers.providers_setup_addresses_address_path
      when :address
        url_helpers.new_provider_confirm_path
      else
        raise ArgumentError, "Unknown step: #{@current_step}"
      end
    end

    def back_path
      case @current_step
      when :type
        url_helpers.new_provider_onboarding_path
      when :details
        url_helpers.new_provider_type_path
      when :accreditation
        url_helpers.new_provider_details_path
      when :address
        if @provider&.accredited?
          url_helpers.new_provider_accreditation_path
        else
          url_helpers.new_provider_details_path
        end
      when :check_answers
        url_helpers.providers_setup_addresses_address_path
      else
        raise ArgumentError, "Unknown step: #{@current_step}"
      end
    end

  private

    def from_check_page?
      @goto_param == "confirm"
    end

    def url_helpers
      Rails.application.routes.url_helpers
    end
  end
end
