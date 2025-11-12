module AddressJourney
  class Finder
    include ServicePattern

    def initialize(postcode:, building_name_or_number:, session_manager:)
      @postcode = postcode
      @building_name_or_number = building_name_or_number
      @session_manager = session_manager
    end

    def call
      form = Addresses::FindForm.new(
        postcode: @postcode,
        building_name_or_number: @building_name_or_number
      )

      return failure(form:) unless form.valid?

      results = OrdnanceSurvey::AddressLookupService.call(
        postcode: @postcode,
        building_name_or_number: @building_name_or_number
      )

      @session_manager.store_search(
        postcode: @postcode,
        building_name_or_number: @building_name_or_number,
        results: results
      )

      success(results:)
    end

  private

    def success(results:)
      { success: true, results: results }
    end

    def failure(form:)
      { success: false, form: form }
    end
  end
end
