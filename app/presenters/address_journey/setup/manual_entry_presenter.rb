module AddressJourney
  module Setup
    class ManualEntryPresenter < BasePresenter
      attr_reader :form, :address

      def initialize(form:, provider:, address: nil)
        super(provider:)
        @form = form
        @address = address
      end

      def form_url
        providers_setup_addresses_address_path
      end

      def form_method
        :post
      end

      def page_title
        "Add address"
      end

      def page_subtitle
        "Add provider"
      end

      def page_caption
        "Add provider"
      end

      delegate :back_path, to: :journey_service

      def cancel_path
        providers_path
      end
    end
  end
end
