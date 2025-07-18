class ProvidersController < ApplicationController
  def index
    [Providers::IsTheProviderAccredited,
     Providers::ProviderType,
     Provider,].each do |form|
      current_user.clear_temporary(form, purpose: :check_your_answers)
    end
  end

  def new
    @form = current_user.load_temporary(Providers::IsTheProviderAccredited,
                                        purpose: :check_your_answers)
  end

  def create
    @form = Providers::IsTheProviderAccredited.new(accreditation_status_params)

    if @form.valid?
      @form.save_as_temporary!(created_by: current_user, purpose: :check_your_answers)
      redirect_to new_type_providers_path
    else
      render :new
    end
  end

  def new_type
    is_the_provider_accredited_form = current_user.load_temporary(Providers::IsTheProviderAccredited,
                                                                  purpose: :check_your_answers)

    if is_the_provider_accredited_form.nil? || is_the_provider_accredited_form.invalid?

      # NOTE: Something is really wrong if we reach here, redirect to the new provider form
      redirect_to new_providers_path
      return
    end

    @form = current_user.load_temporary(Providers::ProviderType,
                                        purpose: :check_your_answers)

    @form.assign_attributes(is_the_provider_accredited_form.attributes)

    render :new_type
  end

  def create_type
    @form = Providers::ProviderType.new(create_new_type_provider_params)

    if @form.valid?
      @form.save_as_temporary!(created_by: current_user, purpose: :check_your_answers)
      redirect_to new_details_providers_path
    else
      render :new_type
    end
  end

  def new_details
    is_the_provider_accredited_form = current_user.load_temporary(Providers::IsTheProviderAccredited,
                                                                  purpose: :check_your_answers)

    if is_the_provider_accredited_form.nil? || is_the_provider_accredited_form.invalid?

      # NOTE: Something is really wrong if we reach here, redirect to the new provider form
      redirect_to new_providers_path
      return
    end

    provider_type = current_user.load_temporary(Providers::ProviderType,
                                                purpose: :check_your_answers)

    if provider_type.nil? || provider_type.invalid?

      # NOTE: Something is really wrong if we reach here, redirect to the new provider form
      redirect_to new_type_providers_path
      return
    end

    @provider = Provider.new(provider_type.attributes)

    render :new_details
  end

  def create_details
    @provider = Provider.new(create_new_provider_params)

    if @provider.valid?
      @provider.save_as_temporary!(created_by: current_user, purpose: :check_your_answers)
      redirect_to providers_path, flash: { success: "Provider added" }
    else
      render :new_details
    end
  end

private

  def accreditation_status_params
    params.expect(provider: [:accreditation_status])
  end

  def create_new_type_provider_params
    params.expect(provider: [:provider_type, :accreditation_status])
  end

  def create_new_provider_params
    params.expect(provider: [:provider_type, :accreditation_status, :operating_name, :ukprn, :code, :urn, :legal_name])
  end
end
