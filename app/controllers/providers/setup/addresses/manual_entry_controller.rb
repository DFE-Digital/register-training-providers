module Providers
  module Setup
    module Addresses
      class ManualEntryController < ApplicationController
        include AddressFormHandler

        def new
          if provider.nil? || provider.invalid?
            redirect_to new_provider_details_path
            return
          end

          unless params[:skip_finder] == "true"
            redirect_to providers_setup_addresses_find_path
            return
          end

          load_address_form
          @presenter = build_address_presenter(@form, :new)
        end

        def create
          create_address
        end

      private

        def address_purpose
          :create_provider
        end

        def address_success_path
          journey_service.next_path
        end

        def context_for_form
          :new
        end

        def setup_address_form_mode
          @form.provider_creation_mode = true
        end

        def build_address_presenter(form, _context, _address = nil)
          AddressJourney::Setup::ManualEntryPresenter.new(form:, provider:)
        end

        def provider
          @provider ||= current_user.load_temporary(Provider, purpose: :create_provider)
        end

        def journey_service
          @journey_service ||= Providers::CreationJourneyService.new(
            current_step: :address,
            provider: provider,
            goto_param: params[:goto]
          )
        end
      end
    end
  end
end
