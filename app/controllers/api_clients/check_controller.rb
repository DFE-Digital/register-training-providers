class ApiClients::CheckController < CheckController
private

  def model_class
    method == :post ? ApiClientForm : ApiClient
  end

  def model_id
    @model_id ||= params[:id] || params[:api_client_id]
  end

  def purpose
    :check_your_answers
  end

  def model
    @model ||= current_user.load_temporary(model_class, id: model_id, purpose: purpose)
  end

  def success_path(model, expires_at: nil)
    method == :post ? api_client_confirmation_path(api_client_id: model.id, expires_at:) : api_clients_path
  end

  def find_existing_record
    ApiClient.kept.find(model_id)
  end

  def build_new_record
    model_class.build(model_attributes)
  end

  def model_attributes
    model.to_api_client_attributes
  end

  def new_model_path(query_params = {})
    new_api_client_path(query_params)
  end

  def edit_model_path(query_params = {})
    api_client = ApiClient.kept.find(model_id)
    edit_api_client_path(api_client, query_params)
  end

  def new_model_check_path
    api_client_confirm_path
  end

  def model_check_path
    api_client = ApiClient.kept.find(model_id)
    api_client_check_path(api_client)
  end

  def save
    authorize_model

    if model.valid?
      if method == :post
        api_client = model.save(user: current_user)
        redirect_to success_path(api_client, expires_at: model.expires_at)
      else
        model.save!
        redirect_to success_path(model), flash: flash_message
      end
    else
      # NOTE: if it failed there is something really wrong send them back to the form
      # and let them trigger the validation again
      redirect_to back_path
    end
  end

  def authorize_model
    return authorize model if model.instance_of?(ApiClient)

    api_client = ApiClient.new

    authorize api_client
  end
end
