module AddressJourney
  class ManualEntryPresenter < BasePresenter
    attr_reader :form, :address, :context, :goto_param, :from_select, :back_path

    def initialize(form:, provider:, context:, back_path:, address: nil, goto_param: nil, from_select: false)
      super(provider:)
      @form = form
      @address = address
      @context = context
      @goto_param = goto_param
      @from_select = from_select
      @back_path = back_path
    end

    def form_url
      if setup_context?
        params = {}
        params[:goto] = @goto_param if @goto_param.present?
        params[:from] = "select" if from_select?
        providers_setup_addresses_address_path(params)
      elsif edit_context?
        params = { provider_id: provider.id }
        params[:goto] = @goto_param if @goto_param.present?
        provider_address_path(address, params)
      else
        params = {}
        params[:goto] = @goto_param if @goto_param.present?
        params[:from] = "select" if from_select?
        provider_addresses_path(provider, params)
      end
    end

    def form_method
      edit_context? ? :patch : :post
    end

    def page_title
      if setup_context?
        "Add address"
      elsif edit_context?
        provider.operating_name.to_s
      else
        "Add address - #{provider.operating_name}"
      end
    end

    def page_subtitle
      if setup_context?
        "Add provider"
      elsif edit_context?
        "Edit address"
      else
        "Add address"
      end
    end

    def page_caption
      if setup_context?
        "Add provider"
      elsif edit_context?
        provider.operating_name.to_s
      else
        "Add address - #{provider.operating_name}"
      end
    end

    def cancel_path
      setup_context? ? providers_path : provider_addresses_path(provider)
    end

  private

    def setup_context?
      !provider.persisted?
    end

    def edit_context?
      context == :edit
    end

    def from_select?
      !!from_select
    end
  end
end
