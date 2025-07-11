class ProvidersController < ApplicationController
  def index
    current_user.clear_temporary(Providers::IsTheProviderAccredited, purpose: :check_your_answers)
  end

  def new
    @form = Providers::IsTheProviderAccredited.new
  end

  def create
    @form = Providers::IsTheProviderAccredited.new(provider_params)

    if @form.valid?
      @form.save_as_temporary!(created_by: current_user, purpose: :check_your_answers)
      redirect_to providers_path, flash: { success: "Provider added" }
    else
      render :new
    end
  end

private

  def provider_params
    params.expect(provider: [:accreditation_status])
  end
end
