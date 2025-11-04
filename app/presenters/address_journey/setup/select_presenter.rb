module AddressJourney
  module Setup
    class SelectPresenter < BasePresenter
      include AddressJourney::Shared::SelectPresenterBehavior

      attr_reader :results, :find_form, :error

      def initialize(results:, find_form:, provider:, error: nil)
        super(provider:)
        @results = results
        @find_form = find_form
        @error = error
      end

      def form_url
        providers_setup_addresses_select_path
      end

      def back_path
        providers_setup_addresses_find_path
      end

      def change_search_path
        providers_setup_addresses_find_path
      end
    end
  end
end
