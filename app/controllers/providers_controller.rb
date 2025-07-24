class ProvidersController < ApplicationController
  include Pagy::Backend

  def index
    [Providers::IsTheProviderAccredited,
     Providers::ProviderType,
     Provider,].each do |form|
      current_user.clear_temporary(form, purpose: :create_provider)
    end

    @pagy, @records = pagy(Provider.kept.order_by_operating_name)
  end

  def show
    @provider = Provider.kept.find(id)
  end

  def edit
    @provider = current_user.load_temporary(Provider, id: id, purpose: :edit_provider)
  end

  def update
    @provider = current_user.load_temporary(Provider, id: id, purpose: :edit_provider)

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

  def id
    params[:id].to_i
  end
end
