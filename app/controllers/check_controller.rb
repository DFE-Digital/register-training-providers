class CheckController < ApplicationController
  helper_method :rows, :save_path, :back_path, :cancel_path, :method, :model

  def show
    redirect_to back_path if model.invalid?
  end

  def new
    redirect_to back_path if model.invalid?
  end

  def create
    save
  end

  def update
    save
  end

private

  def save
    if model.save

      redirect_to success_path, flash: flash_message
    else
      # NOTE: if it failed there is something really wrong send them back to the form
      # and let them trigger the validation again
      redirect_to back_path
    end
  end

  def method
    model_id.present? ? :patch : :post
  end

  def flash_message
    { success: I18n.t("flash_message.success.check.#{model_name}.#{mode}") }
  end

  def cancel_path
    success_path
  end

  def mode
    model_id.present? ? "update" : "add"
  end

  def model_id
    @model_id ||= params["#{model_name}_id"]
  end

  def model
    @model ||= current_user.load_temporary(model_class, id: model_id, purpose: :check_your_answers)
  end

  def model_class
    controller_path.split("/").first.classify.constantize
  end

  def model_name
    model_class.name.underscore
  end

  def new_model_path
    @new_model_path ||= url_for([:new, model_name.to_sym])
  end

  def edit_model_path
    @edit_model_path ||= Rails.application.routes.url_helpers.url_for(
      controller: model_name.pluralize,
      action: "edit",
      id: model,
      only_path: true
    )
  end

  def back_path
    model_id.present? ? edit_model_path : new_model_path
  end

  def success_path
    @success_path ||= url_for([model_name.pluralize.to_sym])
  end

  def save_path
    @save_path ||= if model_id.present?
                     model_check_path
                   else
                     new_model_check_path
                   end
  end

  def new_model_check_path
    @new_model_check_path ||= url_for([model_name.to_sym, :confirm])
  end

  def model_check_path
    @model_check_path ||= url_for([model, :check])
  end

  def rows
    @rows = generate_rows
  end

  def generate_rows
    raise NotImplementedError
  end
end
