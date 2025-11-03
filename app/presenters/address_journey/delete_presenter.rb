module AddressJourney
  class DeletePresenter < BasePresenter
    attr_reader :address

    def initialize(address:, provider:)
      super(provider:)
      @address = address
    end

    def page_title
      "Confirm you want to delete #{provider.operating_name}'s address"
    end

    def page_subtitle
      "Delete address"
    end

    alias_method :page_caption, :page_subtitle

    def back_path
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
