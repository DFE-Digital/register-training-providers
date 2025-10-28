class Providers::AccreditationController < CheckController
  def new
    provider_type = current_user.load_temporary(Providers::ProviderType,
                                                purpose: :create_provider)

    if provider_type.nil? || provider_type.invalid?
      redirect_to new_provider_type_path
      return
    end

    unless provider_type.accredited?
      redirect_to new_provider_confirm_path
      return
    end

    provider = current_user.load_temporary(Provider, purpose: :create_provider)

    if provider.nil? || provider.invalid?
      redirect_to new_provider_details_path
      return
    end

    @form = current_user.load_temporary(AccreditationForm, purpose: :create_provider, reset: false)
    @form.provider_creation_mode = true
    @form.provider_id = provider.id
    @form.provider_type = provider.provider_type

    render :new
  end

  def create
    @form = AccreditationForm.new(create_accreditation_params)
    @form.provider_creation_mode = true

    provider = current_user.load_temporary(Provider, purpose: :create_provider)
    @form.provider_id = provider&.id
    @form.provider_type = provider&.provider_type

    if @form.valid?
      @form.save_as_temporary!(created_by: current_user, purpose: :create_provider)

      redirect_to journey_service(:accreditation, provider).next_path
    else
      render :new
    end
  end

private

  def create_accreditation_params
    params.expect(accreditation: [:number, *AccreditationForm::PARAM_CONVERSION.keys])
      .transform_keys { |k| AccreditationForm::PARAM_CONVERSION.fetch(k, k) }
  end

  def journey_service(current_step, provider)
    Providers::CreationJourneyService.new(
      current_step: current_step,
      provider: provider,
      goto_param: params[:goto]
    )
  end
end
