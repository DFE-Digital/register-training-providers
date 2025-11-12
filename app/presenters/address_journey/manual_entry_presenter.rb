module AddressJourney
  class ManualEntryPresenter < BasePresenter
    attr_reader :form, :address, :context, :goto_param, :from_select

    def initialize(form:, provider:, context:, address: nil, goto_param: nil, from_select: false)
      super(provider:)
      @form = form
      @address = address
      @context = context
      @goto_param = goto_param
      @from_select = from_select
    end

    def form_url
      if edit_context?
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
      if edit_context?
        edit_back_path
      elsif from_select?
        select_back_path
      elsif @goto_param == "confirm"
        provider_new_address_confirm_path(provider)
      else
        provider_new_find_path(provider)
      end
    end

    def cancel_path
      provider_addresses_path(provider)
    end

  private

    def edit_context?
      context == :edit
    end

    def from_select?
      !!from_select
    end

    def edit_back_path
      if @goto_param == "confirm" && address.present?
        provider_address_check_path(address, provider_id: provider.id)
      else
        provider_addresses_path(provider)
      end
    end

    def select_back_path
      params = {}
      params[:goto] = @goto_param if @goto_param.present?
      provider_new_select_path(provider, params)
    end
  end
end
