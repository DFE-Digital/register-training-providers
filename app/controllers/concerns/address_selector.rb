module AddressSelector
  extend ActiveSupport::Concern

  def load_selection_form
    @search_results_form = current_user.load_temporary(
      ::Addresses::SearchResultsForm,
      purpose: search_results_purpose
    )

    if @search_results_form.nil?
      redirect_to find_path
      return false
    end

    @find_form = current_user.load_temporary(
      ::Addresses::FindForm,
      purpose: find_purpose
    )

    @results = @search_results_form.results_array
    @form = ::Addresses::SelectForm.new
    true
  end

  def perform_address_selection
    @search_results_form = current_user.load_temporary(
      ::Addresses::SearchResultsForm,
      purpose: search_results_purpose
    )

    if @search_results_form.nil?
      redirect_to find_path
      return
    end

    @results = @search_results_form.results_array
    @find_form = current_user.load_temporary(
      ::Addresses::FindForm,
      purpose: find_purpose
    )

    @form = ::Addresses::SelectForm.new(selection_params)

    unless @form.valid?
      handle_validation_error
      return
    end

    selected_index = @form.selected_address_index.to_i

    if selected_index.negative? || selected_index >= @results.size
      handle_selection_error("Please select an address")
      return
    end

    selected_address = @results[selected_index]
    address_form = AddressForm.from_os_address(selected_address.symbolize_keys)
    setup_address_form(address_form)

    if address_form.valid?
      save_selected_address(address_form)
      clear_search_temporaries
      redirect_to confirm_path
    else
      error_messages = address_form.errors.full_messages.join(", ")
      handle_selection_error("There was a problem with the selected address: #{error_messages}")
    end
  end

private

  def handle_selection_error(error_message)
    @error = error_message
    @form ||= ::Addresses::SelectForm.new
    @presenter = build_select_presenter(@results, @find_form, @error)
    render :new
  end

  def handle_validation_error
    @presenter = build_select_presenter(@results, @find_form, nil)
    render :new
  end

  def clear_search_temporaries
    current_user.clear_temporary(::Addresses::FindForm, purpose: find_purpose)
    current_user.clear_temporary(::Addresses::SearchResultsForm, purpose: search_results_purpose)
  end

  def setup_address_form(address_form)
    address_form.provider_id = provider.id
  end

  def selection_params
    params.fetch(:select, {}).permit(:selected_address_index)
  end

  # Each controller must implement:
  # - find_purpose
  # - search_results_purpose
  # - find_path
  # - confirm_path
  # - setup_address_form(address_form) (optional, defaults to setting provider_id)
  # - save_selected_address(address_form)
  # - build_select_presenter(results, find_form, error)
  # - provider
end
