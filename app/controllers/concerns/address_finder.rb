module AddressFinder
  extend ActiveSupport::Concern

  def load_find_form
    current_user.clear_temporary(::Addresses::FindForm, purpose: find_purpose)
    current_user.clear_temporary(::Addresses::SearchResultsForm, purpose: search_results_purpose)
    current_user.clear_temporary(AddressForm, purpose: :create_address)

    @form = current_user.load_temporary(::Addresses::FindForm, purpose: find_purpose)
    @form.provider_id = provider.id if @form.provider_id.blank?
  end

  def perform_address_search
    @form = ::Addresses::FindForm.new(find_form_params)
    @form.provider_id = provider.id

    if @form.valid?
      results = OrdnanceSurvey::AddressLookupService.call(
        postcode: @form.postcode,
        building_name_or_number: @form.building_name_or_number
      )

      save_search_results(results)
      @form.save_as_temporary!(created_by: current_user, purpose: find_purpose)

      redirect_to select_path
    else
      @presenter = build_find_presenter(@form)
      render :new
    end
  end

private

  def save_search_results(results)
    search_results_form = ::Addresses::SearchResultsForm.new
    search_results_form.results_array = results
    search_results_form.save_as_temporary!(
      created_by: current_user,
      purpose: search_results_purpose
    )
  end

  def find_form_params
    params.expect(find: [:postcode, :building_name_or_number])
  end

  # Each controller must implement:
  # - find_purpose
  # - search_results_purpose
  # - select_path
  # - build_find_presenter(form)
  # - provider
end
