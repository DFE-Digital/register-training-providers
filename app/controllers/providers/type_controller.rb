class Providers::TypeController < CheckController
  def new
    is_the_provider_accredited_form = current_user.load_temporary(Providers::IsTheProviderAccredited,
                                                                  purpose: :check_your_answers)

    if is_the_provider_accredited_form.nil? || is_the_provider_accredited_form.invalid?

      # NOTE: Something is really wrong if we reach here, redirect to the new provider form
      redirect_to new_provider_onboarding_path
      return
    end

    @form = current_user.load_temporary(Providers::ProviderType,
                                        purpose: :check_your_answers)

    @form.assign_attributes(is_the_provider_accredited_form.attributes)

    render :new
  end

  def create
    @form = Providers::ProviderType.new(create_new_provider_type_params)

    if @form.valid?
      @form.save_as_temporary!(created_by: current_user, purpose: :check_your_answers)
      redirect_to new_provider_details_path
    else
      render :new
    end
  end

private

  def create_new_provider_type_params
    params.expect(provider: [:provider_type, :accreditation_status])
  end
end
