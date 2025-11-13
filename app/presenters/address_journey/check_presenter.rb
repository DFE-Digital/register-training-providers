module AddressJourney
  class CheckPresenter < BasePresenter
    attr_reader :form, :context, :back_path, :change_path, :save_path

    def initialize(form:, provider:, context:, back_path:, change_path:, save_path:, address: nil)
      super(provider:)
      @form = form
      @context = context
      @back_path = back_path
      @change_path = change_path
      @save_path = save_path
      @address = address
    end

    def page_subtitle
      if edit_context?
        provider.operating_name.to_s
      else
        "Add address - #{provider.operating_name}"
      end
    end

    alias_method :page_caption, :page_subtitle

    def save_button_text
      "Save address"
    end

    def form_method
      edit_context? ? :patch : :post
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
