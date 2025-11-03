module AddressFormHandler
  extend ActiveSupport::Concern

  def load_address_form
    @form = current_user.load_temporary(AddressForm, purpose: address_purpose, reset: false)
    @form.provider_id = provider.id if @form.provider_id.blank?
    setup_address_form_mode
  end

  def create_address
    @form = AddressForm.new(address_form_params)
    @form.provider_id = provider.id
    setup_address_form_mode

    if @form.valid?
      @form.save_as_temporary!(created_by: current_user, purpose: address_purpose)
      redirect_to address_success_path
    else
      @presenter = build_address_presenter(@form, context_for_form)
      render :new
    end
  end

private

  def address_form_params
    params.expect(address: [:address_line_1,
                            :address_line_2,
                            :address_line_3,
                            :town_or_city,
                            :county,
                            :postcode,
                            :provider_id])
  end

  # Each controller must implement:
  # - address_purpose
  # - address_success_path
  # - build_address_presenter(form, context, address = nil)
  # - context_for_form
  # - setup_address_form_mode (optional, defaults to no-op)
  # - provider

  def setup_address_form_mode
    # Override in subclass if needed
  end
end
