class Providers::ContactsController < ApplicationController
  def index
    authorize provider, :show?
    @contacts = policy_scope(provider.contacts)
  end

  def new
    # Clear any existing temporary records if not coming from check page
    current_user.clear_temporary(ContactForm, purpose: :create_contact) if params[:goto] != "confirm"

    @form = current_user.load_temporary(ContactForm, purpose: :create_contact)
    @form.assign_attributes(provider_id: provider.id) if @form.provider_id.blank?
    render :new
  end

private

  def provider
    @provider ||= Provider.find(params[:provider_id])
  end
end
