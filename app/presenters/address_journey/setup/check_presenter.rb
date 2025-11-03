module AddressJourney
  module Setup
    class CheckPresenter < BasePresenter
      attr_reader :model, :address

      def initialize(model:, provider:, address: nil)
        super(provider:)
        @model = model
        @address = address
      end

      def page_subtitle
        "Add provider"
      end

      alias_method :page_caption, :page_subtitle

      def back_path
        providers_setup_addresses_address_path(goto: "confirm")
      end

      def save_path
        providers_setup_addresses_confirm_path
      end

      def save_button_text
        "Save address"
      end

      def form_method
        :post
      end

      def change_path
        providers_setup_addresses_address_path(goto: "confirm")
      end
    end
  end
end
