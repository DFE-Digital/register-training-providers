module Providers
  module Setup
    module Addresses
      class CheckController < ::CheckController
        include FormObjectSavePattern

        def show
          @presenter = AddressJourney::Setup::CheckPresenter.new(
            model:,
            provider:
          )
        end

        def new
          redirect_to back_path if model.invalid?

          @presenter = AddressJourney::Setup::CheckPresenter.new(
            model:,
            provider:
          )
        end

      private

        def model_class
          AddressForm
        end

        def model_id
          nil # Always nil in setup context - never editing
        end

        def purpose
          :create_provider
        end

        def model
          @model ||= current_user.load_temporary(model_class, purpose:)
        end

        def success_path
          journey_service.next_path
        end

        def find_existing_record
          nil # Never called in setup context
        end

        def build_new_record
          provider.addresses.build(model_attributes)
        end

        def model_attributes
          model.to_address_attributes
        end

        def new_model_path(query_params = {})
          providers_setup_addresses_address_path(query_params)
        end

        def edit_model_path(query_params = {})
          raise NotImplementedError, "Edit not supported in setup context"
        end

        def new_model_check_path
          providers_setup_addresses_confirm_path
        end

        def model_check_path
          raise NotImplementedError, "Edit not supported in setup context"
        end

        def change_path
          new_model_path(goto: "confirm")
        end

        def address
          nil # Always nil in setup context - never editing
        end

        def provider
          @provider ||= current_user.load_temporary(Provider, purpose: :create_provider)
        end

        def journey_service
          @journey_service ||= Providers::CreationJourneyService.new(
            current_step: :address,
            provider: provider,
            goto_param: nil
          )
        end
      end
    end
  end
end
