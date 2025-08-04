class ProvidersController < ApplicationController
  include Pagy::Backend

  def index
    [
      Providers::IsTheProviderAccredited,
      Providers::ProviderType,
      Provider,
    ].each do |form|
      current_user.clear_temporary(form, purpose: :create_provider)
    end

    @pagy, @records = pagy(scoped_provider.order_by_operating_name, limit: 10)
  end

  def show
    current_user.clear_temporary(scoped_provider, purpose: :edit_provider)

    @provider = scoped_provider.find_by(uuid:)
    authorize @provider
  end

  def edit
    @provider = current_user.load_temporary(scoped_provider, uuid: uuid, purpose: :edit_provider)
    authorize @provider
  end

  def update
    @provider = current_user.load_temporary(scoped_provider, uuid: uuid, purpose: :edit_provider)

    @provider.assign_attributes(params.expect(provider: [:provider_type,
                                                         :accreditation_status,
                                                         :operating_name,
                                                         :ukprn,
                                                         :code,
                                                         :urn,
                                                         :legal_name]))
    if @provider.valid?
      @provider.save_as_temporary!(created_by: current_user, purpose: :edit_provider)
      redirect_to provider_check_path(@provider)
    else
      render(:edit)
    end
  end

private

  def uuid
    params[:id]
  end

  def scoped_provider
    @scoped_provider ||= policy_scope(Provider)
  end
end
