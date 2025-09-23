class AccreditationsController < ApplicationController
  helper_method :back_path

  def index
    authorize provider.accreditations.build
    @accreditations = policy_scope(provider.accreditations).order_by_start_date
  end

  def new
    @provider = provider
    @form = current_user.load_temporary(AccreditationForm, purpose: create_purpose, reset: params[:goto] != "confirm")
    @form.provider_id = provider.id
    @form.provider_type = provider.provider_type
    authorize @form
  end

  def edit
    @provider = provider
    @accreditation = provider.accreditations.kept.find(params[:id])
    authorize @accreditation

    stored_form = current_user.load_temporary(
      AccreditationForm,
      purpose: edit_purpose(@accreditation),
      reset: params[:goto] != "confirm"
    )

    @form = if stored_form.number.present?
              stored_form
            else
              AccreditationForm.from_accreditation(@accreditation)
            end
  end

  def create
    @form = AccreditationForm.new(accreditation_form_params)
    @form.provider_id = provider.id
    @form.provider_type = provider.provider_type
    authorize @form

    if @form.valid?
      @form.save_as_temporary!(created_by: current_user, purpose: create_purpose)
      redirect_to new_accreditation_confirm_path(provider_id: provider.id)
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
    params.expect(accreditation: [:number, *AccreditationForm::PARAM_CONVERSION.keys])
      .transform_keys { |k| AccreditationForm::PARAM_CONVERSION.fetch(k, k) }
  end

  def edit_purpose(accreditation)
    :"edit_accreditation_#{accreditation.id}"
  end

  def create_purpose
    :"create_accreditation_#{provider.id}"
  end

  def back_path
    if params[:goto] == "confirm"
      if action_name == "edit"
        accreditation_check_path(@accreditation, provider_id: provider.id)
      else
        new_accreditation_confirm_path(provider_id: provider.id)
      end
    else
      provider_accreditations_path(provider)
    end
  end
end
