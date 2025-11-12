module Providers
  module Addresses
    class FindController < ApplicationController
      def new
        # Clear session when starting a fresh journey (no goto param means not navigating within existing journey)
        if params[:goto].blank?
          address_session.clear!
        elsif params[:goto] == "confirm" && setup_context?
          # Mark that we came from check page for proper back navigation
          address_session.mark_from_check!
        end

        # Pre-fill form with previous search if available
        search_data = address_session.load_search
        @form = if search_data
                  ::Addresses::FindForm.new(
                    postcode: search_data[:postcode],
                    building_name_or_number: search_data[:building_name_or_number]
                  )
                else
                  ::Addresses::FindForm.new
                end

        @presenter = build_find_presenter(@form)
      end

      def create
        result = AddressJourney::Finder.call(
          postcode: params.dig(:find, :postcode),
          building_name_or_number: params.dig(:find, :building_name_or_number),
          session_manager: address_session
        )

        if result[:success]
          redirect_to select_path
        else
          @form = result[:form]
          @presenter = build_find_presenter(@form)
          render :new
        end
      end

    private

      def provider
        @provider ||= if params[:provider_id]
                        Provider.find(params[:provider_id])
                      else
                        provider_session.load_provider || Provider.new
                      end
      end

      def setup_context?
        params[:provider_id].blank?
      end

      def address_session
        context = setup_context? ? :setup : :manage
        @address_session ||= AddressJourney::SessionManager.new(session, context:)
      end

      def provider_session
        @provider_session ||= ProviderCreation::SessionManager.new(session)
      end

      def journey_coordinator
        @journey_coordinator ||= ProviderCreation::JourneyCoordinator.new(
          current_step: :address_find,
          session_manager: provider_session,
          provider: provider,
          from_check: params[:goto] == "confirm",
          address_session: address_session
        )
      end

      def select_path
        if setup_context?
          providers_setup_addresses_select_path(goto: params[:goto])
        else
          provider_new_select_path(provider)
        end
      end

      def back_path
        if setup_context?
          journey_coordinator.back_path
        else
          provider_addresses_path(provider)
        end
      end

      def build_find_presenter(form)
        if setup_context?
          AddressJourney::Setup::FindPresenter.new(
            form:,
            provider:,
            back_path:
          )
        else
          AddressJourney::FindPresenter.new(
            form:,
            provider:
          )
        end
      end
    end
  end
end
