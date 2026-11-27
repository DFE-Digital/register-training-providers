class AccreditationsController < ApplicationController
  include AccreditationJourneyController

  helper_method :back_path, :cancel_path

  def index
    authorize provider.accreditations.build
    @accreditations = policy_scope(provider.accreditations).order_by_start_date
  end

  def new
    @provider = provider
    accreditation_data = accreditation_session.load_accreditation
    @form = if accreditation_data
              Accreditations::NumberForm.new({number: accreditation_data[:number]})
            else
              Accreditations::NumberForm.new
            end

    @form.provider_id = provider.id

    authorize @form
  end

  def edit
    @provider = provider
    @accreditation = provider.accreditations.kept.find(params[:id])
    authorize @accreditation

    stored_form = current_user.load_temporary(
      AccreditationForm,
      purpose: edit_purpose(@accreditation),
      reset: false
    )

    @form = if stored_form.number.present?
              stored_form
            else
              AccreditationForm.from_accreditation(@accreditation)
            end
  end

  def create
    @form = Accreditations::NumberForm.new(accreditation_form_params)
    @form.provider_id = provider.id
    @form.provider_type = provider.provider_type
    authorize @form

    if @form.valid?
      accreditation_session.store_accreditation(@form.attributes)
      redirect_to success_path
    else
      @provider = provider
      render :new
    end
  end

  def update
    @accreditation = provider.accreditations.kept.find(params[:id])
    authorize @accreditation

    @form = AccreditationForm.new(accreditation_form_params)
    @form.provider_id = provider.id
    @form.provider_type = provider.provider_type

    if @form.valid?
      @form.save_as_temporary!(created_by: current_user, purpose: edit_purpose(@accreditation))
      redirect_to accreditation_check_path(@accreditation, provider_id: provider.id)
    else
      @provider = provider
      render :edit
    end
  end

private

  def accreditation_form_params
    params.expect(accreditation: [:number])
  end

  def edit_purpose(accreditation)
    :"edit_accreditation_#{accreditation.id}"
  end

  def create_purpose
    :"create_accreditation_#{provider.id}"
  end

  def back_path
    provider_accreditations_path(provider)
  end

  def success_path
    provider_new_accreditation_start_date_path(provider_id: provider.id)
  end

  def cancel_path
    provider_accreditations_path(provider)
  end
end
