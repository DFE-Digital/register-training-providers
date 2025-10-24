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

      @form = current_user.load_temporary(AddressForm, purpose: :create_provider, reset: false)
      @form.provider_creation_mode = true
      @form.provider_id = @provider.id if @form.provider_id.blank?
    else
      # Existing provider flow - redirect to finder unless explicitly skipping
      unless params[:skip_finder] == "true"
        redirect_to new_provider_find_path(provider_id: provider.id)
        return
      end

      current_user.clear_temporary(AddressForm, purpose: :create_address) if params[:goto] != "confirm"
      @form = current_user.load_temporary(AddressForm, purpose: :create_address)
      @form.assign_attributes(provider_id: provider.id) if @form.provider_id.blank?
    end

    @presenter = AddressFormPresenter.new(
      form: @form,
      provider: provider,
      context: provider_creation_context? ? :create_provider : :existing_provider
    )

    render :new
  end

  def edit
    @address = provider.addresses.kept.find(params[:id])
    authorize @address

    stored_form = current_user.load_temporary(
      AddressForm,
      purpose: edit_purpose(@address),
      reset: false
    )

    @form = if stored_form.address_line_1.present?
              stored_form
            else
              AddressForm.from_address(@address)
            end

    @presenter = AddressFormPresenter.new(
      form: @form,
      provider: provider,
      address: @address,
      context: :edit
    )
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

        redirect_to journey_service(:address, @provider).next_path
      else
        @presenter = AddressFormPresenter.new(
          form: @form,
          provider: provider,
          context: :create_provider
        )
        render :new
      end
    elsif @form.valid?
      # Existing provider flow
      @form.save_as_temporary!(created_by: current_user, purpose: :create_address)
      redirect_to new_provider_address_confirm_path(provider_id: provider.id)
    else
      @presenter = AddressFormPresenter.new(
        form: @form,
        provider: provider,
        context: :existing_provider
      )
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
      @presenter = AddressFormPresenter.new(
        form: @form,
        provider: provider,
        address: @address,
        context: :edit
      )
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

  def journey_service(current_step, provider)
    Providers::CreationJourneyService.new(
      current_step: current_step,
      provider: provider,
      goto_param: params[:goto]
    )
  end
end
