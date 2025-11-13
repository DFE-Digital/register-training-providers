module Providers
  module Addresses
    class ManualEntryController < ApplicationController
      def new
        # Setup mode specific validation
        if setup_context? && (provider.nil? || provider.invalid?)
          redirect_to new_provider_details_path
          return
        end

        unless params[:skip_finder] == "true"
          redirect_to find_path
          return
        end

        # Mark that we came from check page if appropriate
        if params[:goto] == "confirm" && setup_context?
          address_session.mark_from_check!
        end

        # Clear session only when starting completely fresh
        should_clear = params[:skip_finder].blank? && params[:goto].blank? && params[:from].blank?
        address_session.clear! if should_clear

        address_data = address_session.load_address
        @form = address_data ? ::AddressForm.new(address_data) : ::AddressForm.new
        @form.provider_id = provider.id unless setup_context?

        @presenter = AddressJourney::ManualEntryPresenter.new(
          form: @form,
          provider: provider,
          context: :new,
          goto_param: params[:goto],
          from_select: params[:from] == "select",
          back_path: back_path
        )
      end

      def edit
        # Edit only available in manage context
        redirect_to provider_addresses_path(provider) if setup_context?

        @address = provider.addresses.kept.find(params[:id])
        authorize @address

        @form = ::AddressForm.from_address(@address)
        @presenter = AddressJourney::ManualEntryPresenter.new(
          form: @form,
          provider: provider,
          context: :edit,
          address: @address,
          goto_param: params[:goto],
          from_select: false,
          back_path: back_path
        )
      end

      def create
        @form = AddressForm.new(address_params)
        @form.provider_id = provider.id unless setup_context?
        @form.manual_entry = true if @form.respond_to?(:manual_entry=)
        @form.provider_creation_mode = setup_context?

        if @form.valid?
          address_session.store_address(@form.attributes)
          redirect_to success_path
        else
          @presenter = AddressJourney::ManualEntryPresenter.new(
            form: @form,
            provider: provider,
            context: :new,
            goto_param: params[:goto],
            from_select: params[:from] == "select",
            back_path: back_path
          )
          render :new
        end
      end

      def update
        # Update only available in manage context
        redirect_to provider_addresses_path(provider) if setup_context?

        @address = provider.addresses.kept.find(params[:id])
        authorize @address

        @form = ::AddressForm.new(address_params)
        @form.provider_id = provider.id

        if @form.valid?
          address_session.store_address(@form.attributes)
          redirect_to provider_address_check_path(@address, provider_id: provider.id)
        else
          @presenter = AddressJourney::ManualEntryPresenter.new(
            form: @form,
            provider: provider,
            context: :edit,
            address: @address,
            goto_param: params[:goto],
            from_select: false,
            back_path: back_path
          )
          render :edit
        end
      end

    private

      def provider
        @provider ||= if params[:provider_id]
                        Provider.find(params[:provider_id])
                      else
                        provider_session.load_provider
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
          current_step: :address_manual_entry,
          session_manager: provider_session,
          provider: provider,
          from_check: params[:goto] == "confirm",
          address_session: address_session,
          from_select: params[:from] == "select"
        )
      end

      def address_params
        params.expect(address: [:address_line_1,
                                :address_line_2,
                                :address_line_3,
                                :town_or_city,
                                :county,
                                :postcode,
                                :provider_id])
      end

      def find_path
        if setup_context?
          providers_setup_addresses_find_path(goto: params[:goto])
        else
          provider_new_find_path(provider)
        end
      end

      def success_path
        if setup_context?
          # If coming from check page, return to check
          if params[:goto] == "confirm"
            new_provider_confirm_path
          else
            journey_coordinator.next_path
          end
        else
          provider_new_address_confirm_path(provider)
        end
      end

      def back_path
        setup_context? ? journey_coordinator.back_path : manage_back_path
      end

      def manage_back_path
        # Edit mode
        if params[:id]
          if params[:goto] == "confirm"
            address = provider.addresses.kept.find(params[:id])
            provider_address_check_path(address, provider_id: provider.id)
          else
            provider_addresses_path(provider)
          end
        # Coming from select page
        elsif params[:from] == "select"
          query_params = {}
          query_params[:goto] = params[:goto] if params[:goto].present?
          provider_new_select_path(provider, query_params)
        # Coming from check page (change flow)
        elsif params[:goto] == "confirm"
          provider_new_address_confirm_path(provider)
        # Default - from find page
        else
          provider_new_find_path(provider)
        end
      end
    end
  end
end
