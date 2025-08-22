module Providers
  class AccreditationsController < ApplicationController
    before_action :load_provider

    def index
      authorize @provider, :show?
      @accreditations = policy_scope(@provider.accreditations).order_by_start_date
    end

    def new
      @form = current_user.load_temporary(Providers::Accreditation, purpose: :create_accreditation)
      @form.provider_id = @provider.id
    end

    def create
      @form = Providers::Accreditation.new(provider_id: @provider.id)
      @form.assign_attributes(accreditation_params)

      if @form.valid?
        @form.save_as_temporary!(created_by: current_user, purpose: :create_accreditation)
        redirect_to new_provider_accreditation_confirm_path(@provider)
      else
        render :new
      end
    end

  private

    def load_provider
      @provider = policy_scope(Provider).find_by!(uuid: params[:provider_id])
    end

    def accreditation_params
      params
        .expect(accreditation: [:number, *Providers::Accreditation::PARAM_CONVERSION.keys])
        .transform_keys do |key|
          Providers::Accreditation::PARAM_CONVERSION.fetch(key, key)
        end
    end
  end
end
