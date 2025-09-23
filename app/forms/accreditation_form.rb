class AccreditationForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include SaveAsTemporary
  include GovukDateValidation
  include GovukDateComponents

  has_date_components :start_date, :end_date

  attribute :number, :string
  attribute :provider_id, :string
  attribute :provider_creation_mode, :boolean, default: false
  attribute :provider_type, :string

  def self.model_name
    ActiveModel::Name.new(self, nil, "Accreditation")
  end

  def self.i18n_scope
    :activerecord
  end

  def self.from_accreditation(accreditation)
    form = new
    date_attributes = form.extract_date_components_from(accreditation)

    new(date_attributes.merge(
          number: accreditation.number,
          provider_id: accreditation.provider_id,
          provider_type: accreditation.provider&.provider_type
        ))
  end

  validates :number, presence: true, accreditation_number: true
  validates :provider_id, presence: true, unless: :provider_creation_mode?
  validates_govuk_date :start_date, required: true, human_name: "date accreditation starts"
  validates_govuk_date :end_date, required: false, same_or_after: :start_date, human_name: "date accreditation ends"

  def initialize(attributes = {})
    super
    convert_date_components unless start_date.present? || end_date.present?
  end

  def to_accreditation_attributes
    convert_date_components
    {
      number:,
      start_date:,
      end_date:,
      provider_id:
    }.compact
  end

  def provider_creation_mode?
    provider_creation_mode
  end
end
