module AddressJourney
  class FindPresenter < BasePresenter
    attr_reader :form, :back_path

    def initialize(form:, provider:, back_path:, context: nil)
      super(provider:)
      @form = form
      @back_path = back_path
      @context = context
    end

    def form_url
      if setup_context?
        providers_setup_addresses_find_path
      else
        provider_find_path(provider)
      end
    end

    def page_title
      "Find address"
    end

    def page_subtitle
      setup_context? ? "Add provider" : super
    end

    def page_caption
      setup_context? ? "Add provider" : nil
    end

    def cancel_path
      setup_context? ? providers_path : provider_addresses_path(provider)
    end

    def manual_entry_path
      if setup_context?
        providers_setup_addresses_address_path(skip_finder: "true")
      else
        provider_new_address_path(provider, skip_finder: "true")
      end
    end

  private

    def setup_context?
      # Use explicit context if provided, otherwise fall back to checking if provider_id param exists
      # (context will be :setup during provider creation, :manage when adding/editing addresses on existing provider)
      @context == :setup || (@context.nil? && !provider.persisted?)
    end
  end
end
