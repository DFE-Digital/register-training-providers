module AddressJourney
  class CheckPresenter < BasePresenter
    attr_reader :model, :address, :context, :current_user, :goto_param

    def initialize(model:, provider:, context:, address: nil, current_user: nil, goto_param: nil)
      super(provider:)
      @model = model
      @address = address
      @context = context
      @current_user = current_user
      @goto_param = goto_param
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
      if goto_confirm?
        confirm_back_path
      elsif edit_context?
        provider_edit_address_path(address, provider_id: provider.id, goto: "confirm")
      elsif search_results_available?
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
      elsif manual_entry_only?
        provider_new_address_path(provider, goto: "confirm", skip_finder: "true")
      elsif search_results_available?
        provider_new_select_path(provider, goto: "confirm")
      else
        provider_new_address_path(provider, goto: "confirm", skip_finder: "true")
      end
    end

  private

    def edit_context?
      context == :edit
    end

    def search_results_available?
      return false unless current_user

      search_results_form = current_user.load_temporary(
        ::Addresses::SearchResultsForm,
        purpose: :"address_search_results_#{provider.id}"
      )
      return false unless search_results_form

      results = search_results_form.results_array
      results.present? && results.any?
    end

    def goto_confirm?
      goto_param == "confirm"
    end

    def confirm_back_path
      if edit_context?
        provider_address_check_path(address, provider_id: provider.id)
      else
        provider_new_address_confirm_path(provider)
      end
    end

    def manual_entry_only?
      return false if edit_context?

      form = current_user&.load_temporary(AddressForm, purpose: :create_address)
      return false unless form

      form.manual_entry?
    end
  end
end
