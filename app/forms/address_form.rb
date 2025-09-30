class AddressForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations::Callbacks
  include SaveAsTemporary

  # include PostcodeValidator

  attribute :address_line_1, :string
  attribute :address_line_2, :string
  attribute :address_line_3, :string
  attribute :town_or_city, :string
  attribute :county, :string
  attribute :postcode, :string
  attribute :provider_id, :string

  def self.model_name
    ActiveModel::Name.new(self, nil, "Address")
  end

  def self.i18n_scope
    :activerecord
  end

  def self.from_address(address)
    new(
      address_line_1: address.address_line_1,
      address_line_2: address.address_line_2,
      address_line_3: address.address_line_3,
      town_or_city: address.town_or_city,
      county: address.county,
      postcode: address.postcode,
      provider_id: address.provider_id
    )
  end

  before_validation :normalize_postcode

  validates :address_line_1, presence: true, length: { maximum: 255 }
  validates :address_line_2, length: { maximum: 255 }, allow_blank: true
  validates :address_line_3, length: { maximum: 255 }, allow_blank: true
  validates :town_or_city, presence: true, length: { maximum: 255 }
  validates :county, length: { maximum: 255 }, allow_blank: true
  validates :postcode, presence: true, postcode: true
  validates :provider_id, presence: true

  def to_address_attributes
    {
      address_line_1:,
      address_line_2:,
      address_line_3:,
      town_or_city:,
      county:,
      postcode:,
      provider_id:
    }.compact
  end

  alias_method :serializable_hash, :attributes

private

  def normalize_postcode
    return if postcode.blank?

    postcode.upcase!
    postcode.strip!
  end
end
