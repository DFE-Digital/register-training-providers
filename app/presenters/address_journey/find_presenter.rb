module AddressJourney
  class FindPresenter < BasePresenter
    attr_reader :form

    def initialize(form:, provider:)
      super(provider:)
      @form = form
    end

    def form_url
      provider_find_path(provider)
    end

    def page_title
      "Find address"
    end

    def back_path
      provider_addresses_path(provider)
    end
  end
end
