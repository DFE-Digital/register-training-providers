module ProviderCreation
  class JourneyCoordinator
    include Rails.application.routes.url_helpers

    def initialize(current_step:, session_manager:, provider: nil, from_check: false, address_session: nil,
                   from_select: false)
      @current_step = current_step.to_sym
      @session_manager = session_manager
      @provider = provider
      @from_check = from_check
      @address_session = address_session
      @from_select = from_select
    end

    def next_path
      # If we're in a change flow (from check page with goto=confirm),
      # redirect back to check page after successful submission
      if @from_check && [:type, :details, :accreditation].include?(@current_step)
        return new_provider_confirm_path
      end

      case @current_step
      when :onboarding
        new_provider_type_path
      when :type
        new_provider_details_path
      when :details
        provider = load_provider
        if provider&.accredited?
          new_provider_accreditation_path
        else
          providers_setup_addresses_address_path
        end
      when :accreditation
        providers_setup_addresses_find_path
      when :address, :address_find, :address_select, :address_manual_entry
        new_provider_confirm_path
      else
        raise ArgumentError, "Unknown step: #{@current_step}"
      end
    end

    def back_path
      # If coming from check page (change flow), handle unwinding
      if @from_check
        return unwind_from_check_page
      end

      # Normal flow - return to previous step in journey
      case @current_step
      when :onboarding
        providers_path
      when :type
        new_provider_onboarding_path
      when :details
        new_provider_type_path
      when :accreditation
        new_provider_details_path
      when :address_find
        # Back from find page goes to previous provider step
        back_to_previous_provider_step
      when :address_select
        # Back from select page goes to find page (with search preserved)
        providers_setup_addresses_find_path
      when :address_manual_entry
        # Back from manual entry - check if we came from select
        if @from_select || (@address_session && @address_session.search_results_available?)
          providers_setup_addresses_select_path
        else
          # Direct entry, back to find page
          providers_setup_addresses_find_path
        end
      when :check_answers
        # Back from check page to address (manual entry with skip_finder)
        providers_setup_addresses_address_path(skip_finder: "true")
      else
        raise ArgumentError, "Unknown step: #{@current_step}"
      end
    end

  private

    def load_provider
      @provider || @session_manager.load_provider
    end

    # Handle unwinding from check page (change flow with goto=confirm)
    def unwind_from_check_page
      case @current_step
      when :type, :details, :accreditation
        # Simple provider fields - back directly to check
        new_provider_confirm_path
      when :address_find
        # If there are search results available, we came from select via "Change your search"
        # So we should go back to select, not directly to check
        if @address_session && @address_session.search_results_available?
          providers_setup_addresses_select_path(goto: "confirm")
        else
          # First time on find from check: back to check
          new_provider_confirm_path
        end
      when :address_select
        # From Check → Change address → Select: back to check
        new_provider_confirm_path
      when :address_manual_entry
        # Manual entry from change flow - back always returns to check
        # (User is canceling the address change, not navigating within sub-journey)
        new_provider_confirm_path
      else
        # Default: back to check
        new_provider_confirm_path
      end
    end

    # Determine which provider step comes before the address journey
    def back_to_previous_provider_step
      provider = load_provider
      if provider&.accredited?
        new_provider_accreditation_path
      else
        new_provider_details_path
      end
    end
  end
end
