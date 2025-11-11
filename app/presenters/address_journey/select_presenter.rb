module AddressJourney
  class SelectPresenter < BasePresenter
    include AddressJourney::Shared::SelectPresenterBehavior

    attr_reader :results, :find_form, :error, :goto_param

    def initialize(results:, find_form:, provider:, error: nil, goto_param: nil)
      super(provider:)
      @results = results
      @find_form = find_form
      @error = error
      @goto_param = goto_param
    end

    def form_url
      if goto_param.present?
        provider_select_path(provider, goto: goto_param)
      else
        provider_select_path(provider)
      end
    end

    def back_path
      if goto_param.present?
        provider_new_address_confirm_path(provider)
      else
        provider_new_find_path(provider)
      end
    end

    def change_search_path
      provider_new_find_path(provider)
    end

    def manual_entry_path
      query_params = { skip_finder: "true" }
      query_params[:from] = "select" if results.present?
      query_params[:goto] = goto_param if goto_param.present?
      provider_new_address_path(provider, query_params)
    end
  end
end
