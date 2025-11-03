module AddressJourney
  class ManualEntryPresenter < BasePresenter
    attr_reader :form, :address, :context

    def initialize(form:, provider:, context:, address: nil)
      super(provider:)
      @form = form
      @address = address
      @context = context
    end

    def form_url
      if edit_context?
        provider_address_path(address, provider_id: provider.id)
      else
        provider_addresses_path(provider)
      end
    end

    def form_method
      edit_context? ? :patch : :post
    end

    def page_title
      if edit_context?
        provider.operating_name.to_s
      else
        "Add address - #{provider.operating_name}"
      end
    end

    def page_subtitle
      if edit_context?
        "Edit address"
      else
        "Add address"
      end
    end

    def page_caption
      if edit_context?
        provider.operating_name.to_s
      else
        "Add address - #{provider.operating_name}"
      end
    end

    def back_path
      provider_addresses_path(provider)
    end

    def cancel_path
      provider_addresses_path(provider)
    end

  private

    def edit_context?
      context == :edit
    end
  end
end
