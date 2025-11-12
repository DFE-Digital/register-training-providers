class Providers::CheckController < CheckController
  helper_method :change_provider_type_path, :accreditation_form, :change_provider_details_path, :address_form,
                :change_address_path

private

  def model
    @model ||= provider_session.load_provider || Provider.new
  end

  def change_provider_type_path
    if model_id.present?
      edit_provider_path(model, goto: "confirm")
    else
      new_provider_type_path(goto: "confirm")
    end
  end

  def change_provider_details_path
    if model_id.present?
      edit_provider_path(model, goto: "confirm")
    else
      new_provider_details_path(goto: "confirm")
    end
  end

  def back_path
    if model_id.present?
      edit_provider_path(model, goto: "confirm")
    else
      journey_coordinator.back_path
    end
  end

  def purpose
    model_id.present? ? :edit_provider : :create_provider
  end

  def success_path
    if model_id.present?
      provider_path(model)
    else
      providers_path
    end
  end

  def accreditation_form
    return nil unless model.accredited?

    accreditation_data = provider_session.load_accreditation
    return nil unless accreditation_data

    @accreditation_form ||= AccreditationForm.new(accreditation_data)
  end

  def address_form
    return nil if model_id.present?

    address_data = address_session.load_address
    return nil unless address_data

    @address_form ||= ::AddressForm.new(address_data)
  end

  def change_address_path
    return nil if model_id.present?

    if address_manual_entry_only?
      providers_setup_addresses_address_path(skip_finder: "true", goto: "confirm")
    elsif address_search_results_available?
      providers_setup_addresses_select_path(goto: "confirm")
    else
      providers_setup_addresses_address_path(skip_finder: "true", goto: "confirm")
    end
  end

  def save
    authorize model

    if model.save
      save_accreditation_if_present
      save_address_if_present
      clear_temporary_records
      clear_session_data
      redirect_to success_path, flash: flash_message
    else
      redirect_to back_path
    end
  end

  def save_accreditation_if_present
    return unless model.accredited? && accreditation_form&.valid?

    accreditation = model.accreditations.build(accreditation_form.to_accreditation_attributes)
    accreditation.save!
  end

  def save_address_if_present
    return if model_id.present?
    return unless address_form&.valid?

    address = model.addresses.build(address_form.to_address_attributes)
    address.save!
  end

  def clear_temporary_records
    # Provider creation now uses sessions, no temporary records to clear
    # This method kept for backwards compatibility in case other journeys still use it
  end

  def clear_session_data
    # Clear navigation state first in case we need to access other session data
    address_session.clear_navigation_state!

    # Then clear all session data
    provider_session.clear!
    address_session.clear!
  end

  def address_search_results_available?
    return false if model_id.present?

    address_session.search_results_available?
  end

  def address_manual_entry_only?
    return false if model_id.present?

    address_session.manual_entry?
  end

  def journey_coordinator
    @journey_coordinator ||= ProviderCreation::JourneyCoordinator.new(
      current_step: :check_answers,
      session_manager: provider_session,
      provider: model
    )
  end

  def provider_session
    @provider_session ||= ProviderCreation::SessionManager.new(session)
  end

  def address_session
    @address_session ||= AddressJourney::SessionManager.new(session, context: :setup)
  end
end
