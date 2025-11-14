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

  def edit
    @contact = provider.contacts.kept.find(params[:id])
    authorize @contact

    stored_form = current_user.load_temporary(
      ContactForm,
      purpose: edit_purpose(@contact),
      reset: false
    )

    @form = if stored_form.first_name.present?
              stored_form
            else
              ContactForm.from_contact(@contact)
            end

    @presenter = ContactFormPresenter.new(
      form: @form,
      provider: provider,
      contact: @contact,
      context: :edit
    )
  end

  def create
    @form = ContactForm.new(contact_form_params)

    if @form.valid?
      @form.save_as_temporary!(created_by: current_user, purpose: :create_contact)
      redirect_to new_provider_contact_confirm_path(provider_id: provider.id)
    else
      render :new
    end
  end

  def update
    @contact = provider.contacts.kept.find(params[:id])
    authorize @contact

    @form = ContactForm.new(contact_form_params)
    @form.provider_id = provider.id
    @form.id = @contact.id

    if @form.valid?
      @form.save_as_temporary!(created_by: current_user, purpose: edit_purpose(@contact))
      redirect_to provider_contact_check_path(@contact, provider_id: provider.id)
    else
      @presenter = ContactFormPresenter.new(
        form: @form,
        provider: provider,
        contact: @contact,
        context: :edit
      )
      render :edit
    end
  end

private

  def provider
    @provider ||= Provider.find(params[:provider_id])
  end

  def contact_form_params
    params.expect(contact: [:first_name,
                            :last_name,
                            :email,
                            :telephone_number,
                            :provider_id])
  end

  def edit_purpose(contact)
    :"edit_contact_#{contact.id}"
  end
end
