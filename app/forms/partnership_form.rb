class PartnershipForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations::Callbacks
  include GovukDateValidation
  include GovukDateComponents

  has_date_components :start_date, :end_date

  attr_accessor :academic_year_ids

  attribute :provider_id, :string
  attribute :accredited_provider_id, :string

  validates :accredited_provider_id, presence: true
  validates :provider_id, presence: true
  validates :start_date, presence: true
  validate :academic_year_ids_must_not_be_empty

  def self.from_dates(dates)
    form = new

    new(form.extract_date_components_from(dates))
  end

  def self.from_partnership(partnership)
    form = new

    # Create a struct to map duration to start_date/end_date for extract_date_components_from
    dates_object = Struct.new(:start_date, :end_date).new(
      partnership.duration.begin,
      partnership.duration.end.is_a?(Date) ? partnership.duration.end : nil
    )

    new(form.extract_date_components_from(dates_object).merge(
          provider_id: partnership.provider_id,
          accredited_provider_id: partnership.accredited_provider_id,
          academic_year_ids: partnership.academic_year_ids
        ))
  end

  def self.i18n_scope
    :activerecord
  end

  def initialize(attributes = {})
    super
    convert_date_components unless start_date.present? || end_date.present?
  end

  def to_partnership_attributes
    convert_date_components
    {
      duration:,
      provider:,
      accredited_provider:,
      academic_years:
    }.compact
  end

  def provider
    Provider.find(provider_id)
  end

  def accredited_provider
    Provider.find(accredited_provider_id)
  end

  def academic_years
    AcademicYear.where(id: academic_year_ids)
  end

  def duration
    start_date...end_date
  end

private

  def academic_year_ids_must_not_be_empty
    return true unless academic_year_ids.empty?

    errors.add(:academic_year_ids, :blank)
  end
end
