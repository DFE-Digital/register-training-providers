class AccreditationsController < ApplicationController
  before_action :load_provider
  helper_method :back_path

  def index
    authorize @provider.accreditations.build
    @accreditations = policy_scope(@provider.accreditations).order_by_start_date
  end

  def new
    @form = current_user.load_temporary(AccreditationForm, purpose: create_purpose)
    @form.provider_id = @provider.id
    authorize @form
  end

  def edit
    @accreditation = @provider.accreditations.kept.find(params[:id])
    authorize @accreditation

    stored_form = current_user.load_temporary(
      AccreditationForm,
      purpose: edit_purpose(@accreditation)
    )

    @form = if stored_form.number.present?
              stored_form
            else
              AccreditationForm.from_accreditation(@accreditation)
            end
  end

  def create
    @form = AccreditationForm.new(accreditation_form_params)
    @form.provider_id = @provider.id
    authorize @form

    if @form.valid?
      @form.save_as_temporary!(created_by: current_user, purpose: create_purpose)
      redirect_to new_accreditation_confirm_path(provider_id: @provider.id)
    else
      render :new
    end
  end

  def update
    @accreditation = @provider.accreditations.kept.find(params[:id])
    authorize @accreditation

    @form = AccreditationForm.new(accreditation_form_params)
    @form.provider_id = @provider.id

    if @form.valid?
      @form.save_as_temporary!(created_by: current_user, purpose: edit_purpose(@accreditation))
      redirect_to accreditation_check_path(@accreditation, provider_id: @provider.id)
    else
      render :edit
    end
  end

private

  def load_provider
    provider_id = params[:provider_id]
    
    # Check if provider_id is present
    if provider_id.blank?
      Rails.logger.error "AccreditationsController#load_provider: No provider_id provided in params: #{params.inspect}"
      raise ActiveRecord::RecordNotFound, "Provider ID is required"
    end
    
    # Try to find the provider
    @provider = policy_scope(Provider).find_by(id: provider_id)
    
    if @provider.nil?
      # Check if provider exists but is outside policy scope
      provider_exists = Provider.unscoped.find_by(id: provider_id)
      if provider_exists
        if provider_exists.discarded?
          Rails.logger.error "AccreditationsController#load_provider: Provider #{provider_id} is archived"
          raise ActiveRecord::RecordNotFound, "Provider is archived"
        else
          Rails.logger.error "AccreditationsController#load_provider: Provider #{provider_id} exists but is not accessible"
          raise ActiveRecord::RecordNotFound, "Provider is not accessible"
        end
      else
        Rails.logger.error "AccreditationsController#load_provider: Provider #{provider_id} does not exist"
        raise ActiveRecord::RecordNotFound, "Provider with ID #{provider_id} not found"
      end
    end
  end

  def accreditation_form_params
    params.expect(accreditation: [:number, *AccreditationForm::PARAM_CONVERSION.keys])
      .transform_keys { |k| AccreditationForm::PARAM_CONVERSION.fetch(k, k) }
  end

  def edit_purpose(accreditation)
    :"edit_accreditation_#{accreditation.id}"
  end

  def create_purpose
    :"create_accreditation_#{@provider.id}"
  end

  def back_path
    if params[:goto] == "confirm"
      if action_name == "edit"
        accreditation_check_path(@accreditation, provider_id: @provider.id)
      else
        new_accreditation_confirm_path(provider_id: @provider.id)
      end
    else
      provider_accreditations_path(@provider)
    end
  end
end
