module Providers
  module Addresses
    class FindController < ApplicationController
      def new
        # Clear session when starting a fresh journey (no goto param means not navigating within existing journey)
        address_session.clear! if params[:goto].blank?

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

        context = setup_context? ? :setup : :manage
        @presenter = AddressJourney::FindPresenter.new(form: @form, provider: provider, back_path: back_path,
                                                       context: context)
      end

      def create
        @form = ::Addresses::FindForm.new(
          postcode: params.dig(:find, :postcode),
          building_name_or_number: params.dig(:find, :building_name_or_number)
        )

        if @form.valid?
          results = OrdnanceSurvey::AddressLookupService.call(
            postcode: @form.postcode,
            building_name_or_number: @form.building_name_or_number
          )

          address_session.store_search(
            postcode: @form.postcode,
            building_name_or_number: @form.building_name_or_number,
            results: results
          )

          redirect_to select_path
        else
          context = setup_context? ? :setup : :manage
          @presenter = AddressJourney::FindPresenter.new(form: @form, provider: provider, back_path: back_path,
                                                         context: context)
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
        setup_context? ? journey_coordinator.back_path : manage_back_path
      end

      def manage_back_path
        provider_addresses_path(provider)
      end
    end
  end
end
