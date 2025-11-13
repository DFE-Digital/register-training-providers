class Providers::CheckController < CheckController
  helper_method :change_provider_type_path, :accreditation_form, :change_provider_details_path, :address_form,
                :change_address_path

private

  def model
    @model ||= if model_id.present?
                 current_user.load_temporary(Provider, id: model_id, purpose: purpose)
               else
                 provider_session.load_provider || Provider.new
               end
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

    base_path = journey_coordinator.address_entry_path
    return nil unless base_path

    # Add goto parameter to return to check answers page
    uri = URI.parse(base_path)
    params = Rack::Utils.parse_query(uri.query)
    params["goto"] = "confirm"
    uri.query = params.to_query
    uri.to_s
  end

  def save
    authorize model

    if model.save
      save_accreditation_if_present
      save_address_if_present
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

  def clear_session_data
    provider_session.clear!
    address_session.clear!
  end

  def journey_coordinator
    @journey_coordinator ||= ProviderCreation::JourneyCoordinator.new(
      current_step: :check_answers,
      session_manager: provider_session,
      provider: model,
      address_session: address_session
    )
  end

  def provider_session
    @provider_session ||= ProviderCreation::SessionManager.new(session)
  end

  def address_session
    @address_session ||= AddressJourney::SessionManager.new(session, context: :setup)
  end
end
