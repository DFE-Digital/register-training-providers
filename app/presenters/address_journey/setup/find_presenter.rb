module AddressJourney
  module Setup
    class FindPresenter < BasePresenter
      attr_reader :form, :back_path

      def initialize(form:, provider:, back_path:)
        super(provider:)
        @form = form
        @back_path = back_path
      end

      def form_url
        providers_setup_addresses_find_path
      end

      def page_title
        "Find address"
      end
    end
  end
end
