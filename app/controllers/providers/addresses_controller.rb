class Providers::AddressesController < ApplicationController
  def index
    authorize provider, :show?
    @addresses = policy_scope(provider.addresses)
  end

  def new
    if provider_creation_context?
      # Provider creation flow
      @provider = current_user.load_temporary(Provider, purpose: :create_provider)

      if @provider.nil? || @provider.invalid?
        redirect_to new_provider_details_path
        return
      end

      current_user.clear_temporary(AddressForm, purpose: :create_provider) if params[:goto] != "confirm"
      @form = current_user.load_temporary(AddressForm, purpose: :create_provider, reset: params[:goto] != "confirm")
      @form.provider_creation_mode = true
      @form.provider_id = @provider.id if @form.provider_id.blank?

      # Set all view variables for creation context
      @form_url = create_provider_addresses_path
      @form_method = :post
      @page_title = "Add address"
      @page_subtitle = "Add provider"
      @page_caption = "Add provider"
      @back_path = determine_creation_back_path
      @cancel_path = providers_path
    else
      # Existing provider flow
      current_user.clear_temporary(AddressForm, purpose: :create_address) if params[:goto] != "confirm"
      @form = current_user.load_temporary(AddressForm, purpose: :create_address)
      @form.assign_attributes(provider_id: provider.id) if @form.provider_id.blank?

      # Set all view variables for existing provider context
      @form_url = provider_addresses_path(provider)
      @form_method = :post
      @page_title = "Add address - #{provider.operating_name}"
      @page_subtitle = "Add address"
      @page_caption = "Add address - #{provider.operating_name}"
      @back_path = determine_existing_provider_back_path
      @cancel_path = provider_addresses_path(provider)
    end

    render :new
  end

  def edit
    @address = provider.addresses.kept.find(params[:id])
    authorize @address

    stored_form = current_user.load_temporary(
      AddressForm,
      purpose: edit_purpose(@address),
      reset: params[:goto] != "confirm"
    )

    @form = if stored_form.address_line_1.present?
              stored_form
            else
              AddressForm.from_address(@address)
            end

    # Set paths for edit context
    @back_path = if params[:goto] == "confirm"
                   provider_address_check_path(@address,
                                               provider_id: provider)
                 else
                   provider_addresses_path(provider)
                 end
    @cancel_path = provider_addresses_path(provider)
  end

  def create
    @form = AddressForm.new(address_form_params)

    if provider_creation_context?
      # Provider creation flow
      @provider = current_user.load_temporary(Provider, purpose: :create_provider)
      @form.provider_creation_mode = true
      @form.provider_id = @provider&.id

      if @form.valid?
        @form.save_as_temporary!(created_by: current_user, purpose: :create_provider)
        redirect_to new_provider_confirm_path
      else
        render :new
      end
    elsif @form.valid?
      # Existing provider flow
      @form.save_as_temporary!(created_by: current_user, purpose: :create_address)
      redirect_to new_provider_address_confirm_path(provider_id: provider.id)
    else
      render :new
    end
  end

  def update
    @address = provider.addresses.kept.find(params[:id])
    authorize @address

    @form = AddressForm.new(address_form_params)
    @form.provider_id = provider.id

    if @form.valid?
      @form.save_as_temporary!(created_by: current_user, purpose: edit_purpose(@address))
      redirect_to provider_address_check_path(@address, provider_id: provider.id)
    else
      render :edit
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

  def edit_purpose(address)
    :"edit_address_#{address.id}"
  end

  def provider_creation_context?
    params[:provider_id].blank?
  end

  def provider
    @provider ||= if provider_creation_context?
                    current_user.load_temporary(Provider, purpose: :create_provider)
                  else
                    Provider.find(params[:provider_id])
                  end
  end

  def determine_creation_back_path
    return new_provider_confirm_path if params[:goto] == "confirm"

    @provider&.accredited? ? new_provider_accreditation_path : new_provider_details_path
  end

  def determine_existing_provider_back_path
    params[:goto] == "confirm" ? new_provider_address_confirm_path(provider) : provider_addresses_path(provider)
  end
end
