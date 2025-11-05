class ProvidersController < ApplicationController
  include Pagy::Backend
  include DebuggerParamHelper

  helper_method :provider_filters, :keywords

  def index
    [
      Providers::IsTheProviderAccredited,
      Providers::ProviderType,
      Provider,
      AddressForm
    ].each do |form|
      current_user.clear_temporary(form, purpose: :create_provider)
    end
    provider_query = ProvidersQuery.call(filters: provider_filters, search_term: keywords)
    @pagy, @records = pagy(provider_query.order_by_operating_name, limit: 10)
  end

  def show
    current_user.clear_temporary(scoped_provider, purpose: :edit_provider)

    @provider = scoped_provider.find(provider_id)
    authorize @provider
  end

  def edit
    @provider = current_user.load_temporary(scoped_provider, id: provider_id, purpose: :edit_provider)
    authorize @provider
  end

  def update
    @provider = current_user.load_temporary(scoped_provider, id: provider_id, purpose: :edit_provider)

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

  def provider_id
    params[:id]
  end

  def scoped_provider
    @scoped_provider ||= policy_scope(Provider)
  end

  def keywords
    @keywords ||= params.permit(:keywords)[:keywords].presence
  end

  def provider_filters
    @provider_filters ||= begin
      filters = params.fetch(:filters, {}).permit(
        provider_types: [],
        accreditation_statuses: [],
        show_archived: [],
        show_seed_data: []
      ).to_h.with_indifferent_access

      filters.transform_values! { |v| Array(v).compact_blank }

      filters.except!(:show_seed_data) unless debug_mode?

      filters
    end
  end
end
