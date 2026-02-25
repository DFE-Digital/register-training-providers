class ApiClientForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations::Callbacks
  include GovukDateValidation
  include GovukDateComponents
  include SaveAsTemporary

  has_date_components :expires_at

  attribute :name, :string
  attribute :id, :string

  def self.model_name
    ActiveModel::Name.new(self, nil, "ApiClient")
  end

  def self.i18n_scope
    :activerecord
  end

  def self.from_api_client(api_client)
    new

    new(expires_at: api_client.current_authentication_token.expires_at,
        name: api_client.name,
        id: api_client.id,)
  end

  before_validation :convert_date_components

  validates :name, presence: true
  validates_govuk_date :expires_at, presence: true, if: -> { id.blank? }
  validate :expires_at_within_one_year, if: -> { id.blank? }

  def initialize(attributes = {})
    super
    convert_date_components if expires_at.blank?
  end

  def to_api_client_attributes
    convert_date_components
    {
      name:,
      expires_at:,
      id:,
    }.compact
  end

  def save(user:)
    if id.present?
      api_client = ApiClient.kept.find(id:)

      api_client.update!(name:)
    else
      api_client = ApiClient.new(name:)
      ActiveRecord::Base.transaction do
        api_client.save!
        AuthenticationToken.create_with_random_token(api_client: api_client, expires_at: expires_at, created_by: user)
      end
    end

    api_client
  end

private

  def expires_at_within_one_year
    return true unless expires_at.blank? || expires_at <= Time.zone.today || expires_at > Time.zone.today + 1.year

    errors.add(:expires_at, :out_of_range, start: Time.zone.today.to_fs(:govuk),
                                           end: (Time.zone.today + 1.year).to_fs(:govuk))
  end
end
