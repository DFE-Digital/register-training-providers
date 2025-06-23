class CheckController < ApplicationController
  def new
    if model.invalid?
      redirect_to new_model_path
    end

    save_path
    model
    rows
  end

  def create
    if model.save

      redirect_to success_path, flash: flash_message
    else
      # NOTE: if it failed there is something really wrong send them back to the form
      # and let them trigger the validation again
      redirect_to new_model_path
    end
  end

private

  def flash_message
    { success: I18n.t("flash_message.success.check.#{model_name}.#{mode}") }
  end

  def mode
    model.persisted? ? "add" : "update"
  end

  def model
    @model ||= current_user.load_temporary(model_class, purpose: :check_your_answers)
  end

  def model_class
    controller_path.split("/").first.classify.constantize
  end

  def model_name
    model_class.name.underscore
  end

  def model_name_pluralized
    model_name.pluralize
  end

  def new_model_path
    @new_model_path ||= url_for([:new, model_name.to_sym])
  end

  def success_path
    @success_path ||= url_for([model_name_pluralized.to_sym])
  end

  def save_path
    @save_path ||= new_model_check_path
  end

  def new_model_check_path
    @new_model_check_path ||= url_for([model_name.to_sym, :confirm])
  end

  def rows
    @rows = generate_rows
  end

  def generate_rows
    raise NotImplementedError
  end
end
