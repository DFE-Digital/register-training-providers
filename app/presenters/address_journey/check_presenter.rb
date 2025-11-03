module AddressJourney
  class CheckPresenter < BasePresenter
    attr_reader :model, :address, :context

    def initialize(model:, provider:, context:, address: nil)
      super(provider:)
      @model = model
      @address = address
      @context = context
    end

    def page_subtitle
      if edit_context?
        provider.operating_name.to_s
      else
        "Add address - #{provider.operating_name}"
      end
    end

    alias_method :page_caption, :page_subtitle

    def back_path
      if edit_context?
        provider_edit_address_path(address, provider_id: provider.id, goto: "confirm")
      else
        provider_new_address_path(provider, goto: "confirm")
      end
    end

    def save_path
      if edit_context?
        provider_address_check_path(address, provider_id: provider.id)
      else
        provider_address_confirm_path(provider)
      end
    end

    def save_button_text
      "Save address"
    end

    def form_method
      edit_context? ? :patch : :post
    end

    def change_path
      if edit_context?
        provider_edit_address_path(address, provider_id: provider.id, goto: "confirm")
      else
        provider_new_address_path(provider, goto: "confirm")
      end
    end

  private

    def edit_context?
      context == :edit
    end
  end
end
