module AddressJourney
  class CheckPresenter < BasePresenter
    attr_reader :model, :address, :context, :goto_param, :search_available, :manual_entry_only

    def initialize(model:, provider:, context:, address: nil, goto_param: nil, search_available: false,
                   manual_entry_only: false)
      super(provider:)
      @model = model
      @address = address
      @context = context
      @goto_param = goto_param
      @search_available = search_available
      @manual_entry_only = manual_entry_only
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
      if @goto_param == "confirm"
        confirm_back_path
      elsif edit_context?
        provider_edit_address_path(address, provider_id: provider.id, goto: "confirm")
      elsif @manual_entry_only
        # User did manual entry, go back to manual entry page even if search results exist
        provider_new_address_path(provider, goto: "confirm", skip_finder: "true")
      elsif @search_available
        provider_new_select_path(provider)
      else
        provider_new_address_path(provider, goto: "confirm", skip_finder: "true")
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
      elsif @manual_entry_only
        provider_new_address_path(provider, goto: "confirm", skip_finder: "true")
      elsif @search_available
        provider_new_select_path(provider, goto: "confirm")
      else
        provider_new_address_path(provider, goto: "confirm", skip_finder: "true")
      end
    end

  private

    def edit_context?
      context == :edit
    end

    def confirm_back_path
      if edit_context?
        provider_address_check_path(address, provider_id: provider.id)
      else
        provider_new_address_confirm_path(provider)
      end
    end
  end
end
