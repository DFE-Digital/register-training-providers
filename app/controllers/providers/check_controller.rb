class Providers::CheckController < CheckController
  helper_method :change_provider_type_path

private

  def change_provider_type_path
    new_provider_type_path(goto: "confirm")
  end

  def back_path
    new_provider_details_path
  end

  def change_path
    new_provider_details_path(goto: "confirm")
  end

  def purpose
    :create_provider
  end
end
