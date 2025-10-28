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
  validates :telephone_number, presence: true, length: { maximum: 255 }
  validates :provider_id, presence: true
  validate do |record|
    EmailFormatValidator.new(record).validate if email.present?
  end

  alias_method :serializable_hash, :attributes
end
