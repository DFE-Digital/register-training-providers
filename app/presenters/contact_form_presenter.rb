class ContactFormPresenter
  include Rails.application.routes.url_helpers

  attr_reader :form, :contact, :context, :provider

  def initialize(form:, provider:, context:, contact: nil)
    @form = form
    @provider = provider
    @context = context
    @contact = contact
  end

  def form_url
    if edit_context?
      provider_contact_path(contact, provider_id: provider.id)
    else
      provider_contacts_path(provider)
    end
  end

  def form_method
    edit_context? ? :patch : :post
  end

  def page_title
    if edit_context?
      provider.operating_name.to_s
    else
      "Add contact - #{provider.operating_name}"
    end
  end

  def page_subtitle
    if edit_context?
      "Edit contact"
    else
      "Add contact"
    end
  end

  def page_caption
    if edit_context?
      provider.operating_name.to_s
    else
      "Add contact - #{provider.operating_name}"
    end
  end

  def back_path
    provider_contacts_path(provider)
  end

  def cancel_path
    provider_contacts_path(provider)
  end

private

  def edit_context?
    context == :edit
  end
end
