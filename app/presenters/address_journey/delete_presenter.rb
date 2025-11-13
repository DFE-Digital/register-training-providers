module AddressJourney
  class DeletePresenter
    include Rails.application.routes.url_helpers

    attr_reader :address, :provider

    def initialize(address:, provider:)
      @address = address
      @provider = provider
    end

    def page_title
      "Confirm you want to delete #{provider.operating_name}’s address"
    end

    def page_subtitle
      "Delete address"
    end

    alias_method :page_caption, :page_subtitle

    def back_path
      provider_addresses_path(provider)
    end

    def cancel_path
      provider_addresses_path(provider)
    end

    def delete_path
      provider_address_delete_path(address, provider_id: provider.id)
    end

    def warning_text
      "Deleting an address is permanent – you cannot undo it."
    end
  end
end
