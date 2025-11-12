module Providers
  module Setup
    module Addresses
      class FindController < ApplicationController
        def new
          # Clear session when starting a fresh journey (no goto param means not navigating within existing journey)
          if params[:goto].blank?
            address_session.clear!
          elsif params[:goto] == "confirm"
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

          @presenter = AddressJourney::Setup::FindPresenter.new(
            form: @form,
            provider: provider,
            back_path: compute_back_path
          )
        end

        def create
          result = AddressJourney::Finder.call(
            postcode: params.dig(:find, :postcode),
            building_name_or_number: params.dig(:find, :building_name_or_number),
            session_manager: address_session
          )

          if result[:success]
            # Preserve goto param when redirecting to select
            redirect_to providers_setup_addresses_select_path(goto: params[:goto])
          else
            @form = result[:form]
            @presenter = AddressJourney::Setup::FindPresenter.new(
              form: @form,
              provider: provider,
              back_path: compute_back_path
            )
            render :new
          end
        end

      private

        def provider
          @provider ||= provider_session.load_provider || Provider.new
        end

        def address_session
          @address_session ||= AddressJourney::SessionManager.new(session, context: :setup)
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

        def compute_back_path
          # Delegate to JourneyCoordinator for centralized navigation logic
          journey_coordinator.back_path
        end
      end
    end
  end
end
