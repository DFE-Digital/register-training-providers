module Providers
  class CreationJourneyService
    def initialize(current_step:, provider:, goto_param: nil)
      @current_step = current_step.to_sym
      @provider = provider
      @goto_param = goto_param
    end

    def next_path
      return Rails.application.routes.url_helpers.new_provider_confirm_path if from_check_page?

      case @current_step
      when :onboarding
        Rails.application.routes.url_helpers.new_provider_type_path
      when :type
        Rails.application.routes.url_helpers.new_provider_details_path
      when :details
        if @provider.accredited?
          Rails.application.routes.url_helpers.new_provider_accreditation_path
        else
          Rails.application.routes.url_helpers.new_provider_addresses_path
        end
      when :accreditation
        Rails.application.routes.url_helpers.new_provider_addresses_path
      when :address
        Rails.application.routes.url_helpers.new_provider_confirm_path
      else
        raise ArgumentError, "Unknown step: #{@current_step}"
      end
    end

    def back_path
      case @current_step
      when :type
        Rails.application.routes.url_helpers.new_provider_onboarding_path
      when :details
        Rails.application.routes.url_helpers.new_provider_type_path
      when :accreditation
        Rails.application.routes.url_helpers.new_provider_details_path
      when :address
        if @provider&.accredited?
          Rails.application.routes.url_helpers.new_provider_accreditation_path
        else
          Rails.application.routes.url_helpers.new_provider_details_path
        end
      when :check_answers
        Rails.application.routes.url_helpers.new_provider_addresses_path
      else
        raise ArgumentError, "Unknown step: #{@current_step}"
      end
    end

  private

    def from_check_page?
      @goto_param == "confirm"
    end
  end
end
