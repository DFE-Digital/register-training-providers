module AddressJourney
  module Setup
    class SelectPresenter < BasePresenter
      include AddressJourney::Shared::SelectPresenterBehavior

      attr_reader :results, :postcode, :building_name_or_number, :error, :goto_param, :back_path

      def initialize(results:, postcode:, building_name_or_number:, provider:, error: nil, goto_param: nil,
                     back_path: nil)
        super(provider:)
        @results = results
        @postcode = postcode
        @building_name_or_number = building_name_or_number
        @error = error
        @goto_param = goto_param
        @back_path = back_path || compute_back_path
      end

      def form_url
        if @goto_param.present?
          providers_setup_addresses_select_path(goto: @goto_param)
        else
          providers_setup_addresses_select_path
        end
      end

      def change_search_path
        if @goto_param.present?
          providers_setup_addresses_find_path(goto: @goto_param)
        else
          providers_setup_addresses_find_path
        end
      end

      def manual_entry_path
        query_params = { skip_finder: "true" }
        query_params[:from] = "select" if results.present?
        query_params[:goto] = @goto_param if @goto_param.present?
        providers_setup_addresses_address_path(query_params)
      end

    private

      def compute_back_path
        if @goto_param == "confirm"
          new_provider_confirm_path
        else
          providers_setup_addresses_find_path
        end
      end
    end
  end
end
