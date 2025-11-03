module AddressJourney
  class BasePresenter
    include Rails.application.routes.url_helpers

    attr_reader :provider

    def initialize(provider:)
      @provider = provider
    end

    def page_subtitle
      provider.operating_name.to_s
    end

    def page_caption
      "Add address - #{provider.operating_name}"
    end

    def cancel_path
      provider_addresses_path(provider)
    end

    def manual_entry_path
      provider_new_address_path(provider, skip_finder: true)
    end
  end
end
