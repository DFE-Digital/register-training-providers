module Providers
  module Addresses
    class ManualEntryController < ApplicationController
      include AddressFormHandler

      def new
        unless params[:skip_finder] == "true"
          redirect_to provider_new_find_path(provider)
          return
        end

        if params[:goto] != "confirm"
          current_user.clear_temporary(AddressForm, purpose: address_purpose)
          clear_address_search_temporaries unless from_select?
        end

        load_address_form
        @presenter = build_address_presenter(@form, :new)
      end

      def edit
        @address = provider.addresses.kept.find(params[:id])
        authorize @address

        stored_form = current_user.load_temporary(
          AddressForm,
          purpose: edit_purpose(@address),
          reset: false
        )

        @form = if stored_form.address_line_1.present?
                  stored_form
                else
                  AddressForm.from_address(@address)
                end

        @presenter = build_address_presenter(@form, :edit, @address)
      end

      def create
        create_address
      end

      def update
        @address = provider.addresses.kept.find(params[:id])
        authorize @address

        @form = AddressForm.new(address_form_params)
        @form.provider_id = provider.id

        if @form.valid?
          @form.save_as_temporary!(created_by: current_user, purpose: edit_purpose(@address))
          redirect_to provider_address_check_path(@address, provider_id: provider.id)
        else
          @presenter = build_address_presenter(@form, :edit, @address)
          render :edit
        end
      end

    private

      def address_purpose
        :create_address
      end

      def address_success_path
        provider_new_address_confirm_path(provider_id: provider.id)
      end

      def context_for_form
        :new
      end

      def edit_purpose(address)
        :"edit_address_#{address.id}"
      end

      def build_address_presenter(form, context, address = nil)
        AddressJourney::ManualEntryPresenter.new(
          form: form,
          provider: provider,
          context: context,
          address: address,
          goto_param: params[:goto],
          from_select: from_select?
        )
      end

      def provider
        @provider ||= Provider.find(params[:provider_id])
      end

      def clear_address_search_temporaries
        current_user.clear_temporary(::Addresses::FindForm, purpose: :"find_address_#{provider.id}")
        current_user.clear_temporary(::Addresses::SearchResultsForm, purpose: :"address_search_results_#{provider.id}")
      end

      def from_select?
        params[:from] == "select"
      end

      def setup_address_form_mode
        @form.manual_entry = true if @form.respond_to?(:manual_entry=)
      end
    end
  end
end
