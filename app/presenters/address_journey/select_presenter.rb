module AddressJourney
  class SelectPresenter < BasePresenter
    include AddressJourney::Shared::SelectPresenterBehavior

    attr_reader :results, :postcode, :building_name_or_number, :error, :goto_param, :back_path

    def initialize(results:, postcode:, building_name_or_number:, provider:, error: nil, goto_param: nil,
                   back_path:)
      super(provider:)
      @results = results
      @postcode = postcode
      @building_name_or_number = building_name_or_number
      @error = error
      @goto_param = goto_param
      @back_path = back_path
    end

    def form_url
      if setup_context?
        if @goto_param.present?
          providers_setup_addresses_select_path(goto: @goto_param)
        else
          providers_setup_addresses_select_path
        end
      else
        if @goto_param.present?
          provider_select_path(provider, goto: @goto_param)
        else
          provider_select_path(provider)
        end
      end
    end

    def change_search_path
      if setup_context?
        if @goto_param.present?
          providers_setup_addresses_find_path(goto: @goto_param)
        else
          providers_setup_addresses_find_path
        end
      else
        provider_new_find_path(provider)
      end
    end

    def manual_entry_path
      query_params = { skip_finder: "true" }
      query_params[:from] = "select" if results.present?
      query_params[:goto] = @goto_param if @goto_param.present?
      
      if setup_context?
        providers_setup_addresses_address_path(query_params)
      else
        provider_new_address_path(provider, query_params)
      end
    end

    def cancel_path
      setup_context? ? providers_path : provider_addresses_path(provider)
    end

  private

    def setup_context?
      !provider.persisted?
    end
  end
end
