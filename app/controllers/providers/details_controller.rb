class Providers::DetailsController < CheckController
  def new
    is_the_provider_accredited_form = current_user.load_temporary(Providers::IsTheProviderAccredited,
                                                                  purpose: :create_provider)

    if is_the_provider_accredited_form.nil? || is_the_provider_accredited_form.invalid?

      # NOTE: Something is really wrong if we reach here, redirect to the new provider form
      redirect_to new_provider_onboarding_path
      return
    end

    provider_type = current_user.load_temporary(Providers::ProviderType,
                                                purpose: :create_provider)

    if provider_type.nil? || provider_type.invalid?

      # NOTE: Something is really wrong if we reach here, redirect to the new provider form
      redirect_to new_provider_type_path
      return
    end

    @provider = current_user.load_temporary(Provider, purpose: :create_provider)

    @provider.assign_attributes(provider_type.attributes)

    render :new
  end

  def create
    @provider = current_user.load_temporary(Provider, purpose: :create_provider)

    @provider.assign_attributes(create_new_provider_params)

    if @provider.valid?
      @provider.save_as_temporary!(created_by: current_user, purpose: :create_provider)

      if @provider.accredited?
        redirect_to new_provider_accreditation_path
      else
        redirect_to new_provider_addresses_path
      end
    else
      render :new
    end
  end

private

  def create_new_provider_params
    params.expect(provider: [:provider_type, :accreditation_status, :operating_name, :ukprn, :code, :urn, :legal_name])
  end
end
