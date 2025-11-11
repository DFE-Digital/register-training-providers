module AddressJourney
  module Setup
    class ManualEntryPresenter < BasePresenter
      attr_reader :form, :address, :goto_param, :from_select

      def initialize(form:, provider:, address: nil, goto_param: nil, from_select: false)
        super(provider:)
        @form = form
        @address = address
        @goto_param = goto_param
        @from_select = from_select
      end

      def form_url
        params = {}
        params[:goto] = goto_param if goto_param.present?
        params[:from] = "select" if from_select?
        providers_setup_addresses_address_path(params)
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

      def back_path
        if goto_confirm?
          new_provider_confirm_path
        elsif from_select?
          params = {}
          params[:goto] = goto_param if goto_param.present?
          providers_setup_addresses_select_path(params)
        else
          journey_service.back_path
        end
      end

      def cancel_path
        providers_path
      end

    private

      def goto_confirm?
        goto_param == "confirm"
      end

      def from_select?
        !!from_select
      end
    end
  end
end
