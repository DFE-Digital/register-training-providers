class AddressFormPresenter
  include AddressJourneyContext

  attr_reader :form, :address

  def initialize(form:, provider:, context:, address: nil)
    @form = form
    @provider = provider
    @context = context
    @address = address
  end

  def form_url
    if provider_creation_context?
      create_provider_addresses_path
    elsif edit_context?
      provider_address_path(address, provider_id: provider.id)
    else
      provider_addresses_path(provider)
    end
  end

  def form_method
    edit_context? ? :patch : :post
  end

  def page_title
    if provider_creation_context?
      "Add address"
    elsif edit_context?
      provider.operating_name.to_s
    else
      "Add address - #{provider.operating_name}"
    end
  end

  def page_subtitle
    if provider_creation_context?
      "Add provider"
    elsif edit_context?
      "Edit address"
    else
      "Add address"
    end
  end

  def page_caption
    if provider_creation_context?
      "Add provider"
    elsif edit_context?
      provider.operating_name.to_s
    else
      "Add address - #{provider.operating_name}"
    end
  end

  def back_path
    if provider_creation_context?
      journey_service.back_path
    else
      provider_addresses_path(provider)
    end
  end

  def cancel_path
    if provider_creation_context?
      providers_path
    else
      provider_addresses_path(provider)
    end
  end
end
