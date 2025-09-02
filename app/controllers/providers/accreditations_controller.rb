module Providers
  class AccreditationsController < ApplicationController
    before_action :load_provider

    def index
      authorize @provider.accreditations.build
      @accreditations = policy_scope(@provider.accreditations).order_by_start_date
    end

    def new
      @form = current_user.load_temporary(Providers::Accreditation, purpose: create_purpose)
      @form.provider_id = @provider.id
      authorize @form
    end

    def edit
      @accreditation = @provider.accreditations.find_by!(uuid: params[:id])
      authorize @accreditation

      stored_form = current_user.load_temporary(
        Providers::Accreditation,
        purpose: edit_purpose(@accreditation)
      )

      @form = if stored_form.number.present?
                stored_form
              else
                Providers::Accreditation.from_accreditation(@accreditation)
              end
    end

    def create
      @form = Providers::Accreditation.new(accreditation_form_params)
      @form.provider_id = @provider.id
      authorize @form

      if @form.valid?
        @form.save_as_temporary!(created_by: current_user, purpose: create_purpose)
        redirect_to new_provider_accreditation_confirm_path(@provider)
      else
        render :new
      end
    end

    def update
      @accreditation = @provider.accreditations.find_by!(uuid: params[:id])
      authorize @accreditation

      @form = Providers::Accreditation.new(accreditation_form_params)
      @form.provider_id = @provider.id

      if @form.valid?
        @form.save_as_temporary!(created_by: current_user, purpose: edit_purpose(@accreditation))
        redirect_to provider_accreditation_check_path(@provider, @accreditation)
      else
        render :edit
      end
    end

  private

    def load_provider
      @provider = policy_scope(Provider).find_by!(uuid: params[:provider_id])
    end

    def accreditation_form_params
      params.expect(accreditation: [:number, *Providers::Accreditation::PARAM_CONVERSION.keys])
        .transform_keys { |k| Providers::Accreditation::PARAM_CONVERSION.fetch(k, k) }
    end

    def edit_purpose(accreditation)
      :"edit_accreditation_#{accreditation.uuid}"
    end

    def create_purpose
      :"create_accreditation_#{@provider.uuid}"
    end
  end
end
