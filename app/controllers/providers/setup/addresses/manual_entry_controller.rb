module Providers
  module Setup
    module Addresses
      class ManualEntryController < ApplicationController
        def new
          if provider.nil? || provider.invalid?
            redirect_to new_provider_details_path
            return
          end

          unless params[:skip_finder] == "true"
            redirect_to providers_setup_addresses_find_path(goto: params[:goto])
            return
          end

          # Mark that we came from check page if appropriate
          if params[:goto] == "confirm"
            address_session.mark_from_check!
          end

          # Clear session only when starting completely fresh (no skip_finder, goto, or from params)
          # If skip_finder is present, we're navigating within the journey, so preserve session
          should_clear = params[:skip_finder].blank? && params[:goto].blank? && params[:from].blank?
          address_session.clear! if should_clear

          address_data = address_session.load_address
          @form = address_data ? ::AddressForm.new(address_data) : ::AddressForm.new
          @presenter = AddressJourney::Setup::ManualEntryPresenter.new(
            form: @form,
            provider: provider,
            goto_param: params[:goto],
            from_select: params[:from] == "select",
            back_path: compute_back_path
          )
        end

        def create
          result = AddressJourney::ManualEntry.call(
            address_params: address_params,
            session_manager: address_session,
            provider_id: nil,
            manual_entry: true
          )

          if result[:success]
            # If coming from check page, return to check
            if params[:goto] == "confirm"
              redirect_to new_provider_confirm_path
            else
              redirect_to journey_coordinator.next_path
            end
          else
            @form = result[:form]
            @presenter = AddressJourney::Setup::ManualEntryPresenter.new(
              form: @form,
              provider: provider,
              goto_param: params[:goto],
              from_select: params[:from] == "select",
              back_path: compute_back_path
            )
            render :new
          end
        end

      private

        def provider
          @provider ||= provider_session.load_provider
        end

        def address_params
          params.expect(address: [:address_line_1,
                                  :address_line_2,
                                  :address_line_3,
                                  :town_or_city,
                                  :county,
                                  :postcode])
        end

        def address_session
          @address_session ||= AddressJourney::SessionManager.new(session, context: :setup)
        end

        def provider_session
          @provider_session ||= ProviderCreation::SessionManager.new(session)
        end

        def journey_coordinator
          @journey_coordinator ||= ProviderCreation::JourneyCoordinator.new(
            current_step: :address_manual_entry,
            session_manager: provider_session,
            provider: provider,
            from_check: params[:goto] == "confirm",
            address_session: address_session,
            from_select: params[:from] == "select"
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
