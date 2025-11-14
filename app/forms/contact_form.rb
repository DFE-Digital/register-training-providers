class ContactForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations::Callbacks
  include SaveAsTemporary

  attribute :first_name, :string
  attribute :last_name, :string
  attribute :email, :string
  attribute :telephone_number, :string
  attribute :provider_id, :string
  attribute :id, :string

  def self.model_name
    ActiveModel::Name.new(self, nil, "Contact")
  end

  def self.i18n_scope
    :activerecord
  end

  def self.from_contact(contact)
    new(
      first_name: contact.first_name,
      last_name: contact.last_name,
      email: contact.email,
      telephone_number: contact.telephone_number,
      provider_id: contact.provider_id,
      id: contact.id,
    )
  end

  def to_contact_attributes
    {
      first_name:,
      last_name:,
      email:,
      telephone_number:,
      provider_id:,
    }.compact
  end

  validates :first_name, presence: true, length: { maximum: 255 }
  validates :last_name, presence: true, length: { maximum: 255 }
  validates :email, presence: true, length: { maximum: 255 }
  validate :email_unique_per_provider
  validates :telephone_number, length: { maximum: 255 }, allow_blank: true
  validates :provider_id, presence: true
  validate do |record|
    EmailFormatValidator.new(record).validate if email.present?
    UkTelephoneNumberFormatValidator.new(record).validate if telephone_number.present?
  end

  alias_method :serializable_hash, :attributes

private

  def email_unique_per_provider
    return true if provider_id.blank?

    if id.present?
      contact = Contact.find(id)

      return true if email == contact.email
    end

    existing_emails = Provider.find(provider_id).contacts.pluck(:email)
    errors.add(:email, :taken) if existing_emails.include?(email)
  end
end
