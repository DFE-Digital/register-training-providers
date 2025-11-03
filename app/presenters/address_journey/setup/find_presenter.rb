module AddressJourney
  module Setup
    class FindPresenter < BasePresenter
      attr_reader :form

      def initialize(form:, provider:)
        super(provider:)
        @form = form
      end

      def form_url
        providers_setup_addresses_find_path
      end

      def page_title
        "Find address"
      end

      delegate :back_path, to: :journey_service
    end
  end
end
