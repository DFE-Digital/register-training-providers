class Providers::CheckController < CheckController
  helper_method :change_provider_type_path, :accreditation_form, :change_provider_details_path, :address_form,
                :change_address_path

private

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
      new_provider_addresses_path(goto: "confirm")
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

    @accreditation_form ||= current_user.load_temporary(AccreditationForm, purpose: :create_provider)
  end

  def address_form
    return nil if model_id.present?

    @address_form ||= current_user.load_temporary(AddressForm, purpose: :create_provider)
  end

  def change_address_path
    model_id.present? ? nil : new_provider_addresses_path(goto: "confirm")
  end

  def save
    authorize model

    if model.save
      save_accreditation_if_present
      save_address_if_present
      clear_temporary_records
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
    [
      Providers::IsTheProviderAccredited,
      Providers::ProviderType,
      Provider,
      AccreditationForm,
      AddressForm
    ].each do |form_class|
      current_user.clear_temporary(form_class, purpose: :create_provider)
    end
  end
end
