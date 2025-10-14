class Providers::OnboardingController < CheckController
  def new
    @form = current_user.load_temporary(Providers::IsTheProviderAccredited,
                                        purpose: :create_provider)
  end

  def create
    @form = Providers::IsTheProviderAccredited.new(accreditation_status_params)

    if @form.valid?
      @form.save_as_temporary!(created_by: current_user, purpose: :create_provider)

      provider = current_user.load_temporary(Provider, purpose: :create_provider)
      redirect_to journey_service(:onboarding, provider).next_path
    else
      render :new
    end
  end

private

  def journey_service(current_step, provider)
    Providers::CreationJourneyService.new(
      current_step: current_step,
      provider: provider,
      goto_param: params[:goto]
    )
  end

  def accreditation_status_params
    params.expect(provider: [:accreditation_status])
  end
end
