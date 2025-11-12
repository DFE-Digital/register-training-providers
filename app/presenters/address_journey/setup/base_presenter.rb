module AddressJourney
  module Setup
    class BasePresenter
      include Rails.application.routes.url_helpers

      attr_reader :provider

      def initialize(provider:)
        @provider = provider
      end

      def page_subtitle
        "Add provider"
      end

      def page_caption
        "Add provider"
      end

      def cancel_path
        providers_path
      end

      def manual_entry_path
        providers_setup_addresses_address_path(skip_finder: "true")
      end
    end
  end
end
