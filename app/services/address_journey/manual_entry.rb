module AddressJourney
  class ManualEntry
    include ServicePattern

    def initialize(address_params:, session_manager:, provider_id: nil, manual_entry: false)
      @address_params = address_params
      @session_manager = session_manager
      @provider_id = provider_id
      @manual_entry = manual_entry
    end

    def call
      form = AddressForm.new(@address_params)
      form.provider_id = @provider_id if @provider_id
      form.manual_entry = @manual_entry if form.respond_to?(:manual_entry=)
      form.provider_creation_mode = true if @session_manager.context == :setup

      return failure(form:) unless form.valid?

      @session_manager.store_address(form.attributes)

      success(form:)
    end

  private

    def success(form:)
      { success: true, form: form }
    end

    def failure(form:)
      { success: false, form: form }
    end
  end
end
