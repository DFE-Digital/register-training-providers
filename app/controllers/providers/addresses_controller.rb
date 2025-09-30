class Providers::AddressesController < ApplicationController
  def index
    authorize provider, :show?
    @addresses = policy_scope(provider.addresses)
  end

  def new
    # Clear any existing temporary records if not coming from check page
    current_user.clear_temporary(AddressForm, purpose: :create_address) if params[:goto] != "confirm"

    @form = current_user.load_temporary(AddressForm, purpose: :create_address)
    @form.assign_attributes(provider_id: provider.id) if @form.provider_id.blank?
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
  end

  def create
    @form = AddressForm.new(address_form_params)

    if @form.valid?
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

  def provider
    @provider ||= Provider.find(params[:provider_id])
  end
end
