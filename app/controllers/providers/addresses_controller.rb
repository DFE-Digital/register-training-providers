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

  def create
    @form = AddressForm.new(create_address_form_params)

    if @form.valid?
      @form.save_as_temporary!(created_by: current_user, purpose: :create_address)
      redirect_to new_provider_address_confirm_path(provider_id: provider.id)
    else
      render :new
    end
  end

private

  def create_address_form_params
    params.expect(address: [:address_line_1,
                            :address_line_2,
                            :address_line_3,
                            :town_or_city,
                            :county,
                            :postcode,
                            :provider_id])
  end

  def provider
    @provider ||= Provider.find(params[:provider_id])
  end
end
