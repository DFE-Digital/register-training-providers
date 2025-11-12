module AddressJourney
  class Selector
    include ServicePattern

    def initialize(selected_index:, session_manager:, provider_id: nil)
      @selected_index = selected_index
      @session_manager = session_manager
      @provider_id = provider_id
    end

    # Class method to prepare the select form with pre-selected option
    def self.prepare_select_form(session_manager:)
      selected_index = find_selected_index(session_manager)
      ::Addresses::SelectForm.new(selected_address_index: selected_index)
    end

    # Find which index was previously selected (if any)
    def self.find_selected_index(session_manager)
      stored_address = session_manager.load_address
      return nil unless stored_address

      search_data = session_manager.load_search
      return nil unless search_data

      results = search_data[:results]
      return nil unless results

      # Match by address_line_1 and postcode
      results.each_with_index do |result, index|
        if result["address_line_1"] == stored_address["address_line_1"] &&
            result["postcode"] == stored_address["postcode"]
          return index
        end
      end

      nil
    end

    def call
      search_data = @session_manager.load_search
      return missing_search unless search_data

      results = search_data[:results]
      index = @selected_index.to_i

      return invalid_selection unless index >= 0 && index < results.size

      selected = results[index]
      address_form = AddressForm.from_os_address(selected.symbolize_keys)
      address_form.provider_id = @provider_id if @provider_id
      address_form.provider_creation_mode = true if @session_manager.context == :setup

      return invalid_address(address_form) unless address_form.valid?

      @session_manager.store_address(address_form.attributes)

      success(address_form:)
    end

  private

    def success(address_form:)
      { success: true, address_form: address_form }
    end

    def missing_search
      { success: false, error: :missing_search }
    end

    def invalid_selection
      { success: false, error: :invalid_selection, message: "Please select an address" }
    end

    def invalid_address(form)
      { success: false, error: :invalid_address, form: form }
    end
  end
end
