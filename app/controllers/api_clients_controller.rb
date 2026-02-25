class ApiClientsController < ApplicationController
  include Pagy::Backend
  include GovukDateValidation

  def index
    current_user.clear_temporary(ApiClient, purpose: :check_your_answers)

    @pagy, @records = pagy(policy_scope(scoped_api_client))
  end

  def show
    @api_client = scoped_api_client.find(api_client_id)
    authorize @api_client
  end

  def new
    current_user.clear_temporary(ApiClientForm, purpose: :check_your_answers) if params[:goto] != "confirm"
    @form = current_user.load_temporary(ApiClientForm, purpose: :check_your_answers, reset: false)
  end

  def edit
    @api_client = scoped_api_client.find(api_client_id)
    @form = ApiClientForm.from_api_client(@api_client)
    authorize @api_client
  end

  def create
    @form = ApiClientForm.new(api_client_params)

    if @form.valid?
      @form.save_as_temporary!(created_by: current_user, purpose: :check_your_answers)
      redirect_to new_api_client_confirm_path
    else
      render :new
    end
  end

  def update
    @api_client = scoped_api_client.find(api_client_id)
    @api_client.assign_attributes(api_client_params)

    authorize @api_client

    if @api_client.valid?
      @api_client.save_as_temporary!(created_by: current_user, purpose: :check_your_answers)
      redirect_to api_client_check_path(@api_client)
    else
      @form = ApiClientForm.from_api_client(@api_client)
      render :edit
    end
  end

private

  def api_client_id
    params[:id]
  end

  def scoped_api_client
    @scoped_api_client || policy_scope(ApiClient)
  end

  def api_client_params
    params.expect(api_client: [:name, *ApiClientForm::PARAM_CONVERSION.keys])
      .transform_keys { |k| ApiClientForm::PARAM_CONVERSION.fetch(k, k) }
  end

  def back_path
    api_clients_path
  end
end
