module AddressJourney
  module Setup
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
          providers_setup_addresses_select_path(goto: goto_param)
        else
          providers_setup_addresses_select_path
        end
      end

      def back_path
        if goto_param.present?
          new_provider_confirm_path
        else
          providers_setup_addresses_find_path
        end
      end

      def change_search_path
        providers_setup_addresses_find_path
      end

      def manual_entry_path
        query_params = { skip_finder: "true" }
        query_params[:from] = "select" if results.present?
        query_params[:goto] = goto_param if goto_param.present?
        providers_setup_addresses_address_path(query_params)
      end
    end
  end
end
