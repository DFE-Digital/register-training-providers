module Providers
  module Addresses
    class FindController < ApplicationController
      def new
        # Clear session when starting a fresh journey (no goto param means not navigating within existing journey)
        address_session.clear! if params[:goto].blank?

        @form = ::Addresses::FindForm.new
        @presenter = AddressJourney::FindPresenter.new(
          form: @form,
          provider: provider
        )
      end

      def create
        result = AddressJourney::Finder.call(
          postcode: params.dig(:find, :postcode),
          building_name_or_number: params.dig(:find, :building_name_or_number),
          session_manager: address_session
        )

        if result[:success]
          redirect_to provider_new_select_path(provider)
        else
          @form = result[:form]
          @presenter = AddressJourney::FindPresenter.new(
            form: @form,
            provider: provider
          )
          render :new
        end
      end

    private

      def provider
        @provider ||= Provider.find(params[:provider_id])
      end

      def address_session
        @address_session ||= AddressJourney::SessionManager.new(session, context: :manage)
      end
    end
  end
end
