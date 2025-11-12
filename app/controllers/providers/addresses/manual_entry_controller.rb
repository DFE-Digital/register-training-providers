module Providers
  module Addresses
    class ManualEntryController < ApplicationController
      def new
        unless params[:skip_finder] == "true"
          redirect_to provider_new_find_path(provider)
          return
        end

        # Clear session when starting fresh (no goto param and not coming from select)
        address_session.clear! unless params[:goto].present? || params[:from] == "select"

        address_data = address_session.load_address
        @form = address_data ? ::AddressForm.new(address_data) : ::AddressForm.new
        @form.provider_id = provider.id
        @presenter = AddressJourney::ManualEntryPresenter.new(
          form: @form,
          provider: provider,
          context: :new,
          goto_param: params[:goto],
          from_select: params[:from] == "select"
        )
      end

      def edit
        @address = provider.addresses.kept.find(params[:id])
        authorize @address

        @form = ::AddressForm.from_address(@address)
        @presenter = AddressJourney::ManualEntryPresenter.new(
          form: @form,
          provider: provider,
          context: :edit,
          address: @address,
          goto_param: params[:goto],
          from_select: false
        )
      end

      def create
        result = AddressJourney::ManualEntry.call(
          address_params: address_params,
          session_manager: address_session,
          provider_id: provider.id,
          manual_entry: true
        )

        if result[:success]
          redirect_to provider_new_address_confirm_path(provider)
        else
          @form = result[:form]
          @presenter = AddressJourney::ManualEntryPresenter.new(
            form: @form,
            provider: provider,
            context: :new,
            goto_param: params[:goto],
            from_select: params[:from] == "select"
          )
          render :new
        end
      end

      def update
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
            from_select: false
          )
          render :edit
        end
      end

    private

      def provider
        @provider ||= Provider.find(params[:provider_id])
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

      def address_session
        @address_session ||= AddressJourney::SessionManager.new(session, context: :manage)
      end
    end
  end
end
