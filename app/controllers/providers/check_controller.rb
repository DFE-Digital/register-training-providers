class Providers::CheckController < CheckController
  helper_method :change_provider_type_path

private

  def change_provider_type_path
    if model_id.present?
      edit_provider_path(model, goto: "confirm")
    else
      new_provider_type_path(goto: "confirm")
    end
  end

  def back_path
    if model_id.present?
      edit_provider_path(model, goto: "confirm")
    else
      new_provider_details_path(goto: "confirm")
    end
  end

  def purpose
    model_id.present? ? :edit_provider : :create_provider
  end
end
