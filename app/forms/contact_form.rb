class ContactForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations::Callbacks
  include SaveAsTemporary

  attribute :first_name, :string
  attribute :last_name, :string
  attribute :email_address, :string
  attribute :telephone_number, :string
  attribute :provider_id, :string

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
      email_address: contact.email_address,
      telephone_number: contact.telephone_number,
      provider_id: contact.provider_id,
    )
  end

  def to_contact_attributes
    {
      first_name:,
      last_name:,
      email_address:,
      telephone_number:,
      provider_id:,
    }.compact
  end

  validates :first_name, presence: true, length: { maximum: 255 }
  validates :last_name, presence: true, length: { maximum: 255 }
  validates :email_address, presence: true, length: { maximum: 255 }
  validates :telephone_number, presence: true, length: { maximum: 255 }
  validates :provider_id, presence: true

  alias_method :serializable_hash, :attributes
end
