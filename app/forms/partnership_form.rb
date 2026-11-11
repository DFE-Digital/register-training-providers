class PartnershipForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations::Callbacks
  include GovukDateValidation
  include GovukDateComponents

  has_date_components :start_date, :end_date

  attr_accessor :academic_year_ids, :eligible_academic_year_ids

  # Set by the edit journey when saving will revise the partnership (end it
  # today and start a replacement), so the dates can be validated against the
  # record the save will actually write.
  attr_accessor :revision_on

  attribute :provider_id, :string
  attribute :accredited_provider_id, :string

  validates :accredited_provider_id, presence: true
  validates :provider_id, presence: true
  validates :start_date, presence: true
  validate :academic_year_ids_must_not_be_empty
  validate :academic_year_ids_must_be_eligible
  validate :end_date_must_be_after_the_replacement_start, if: -> { revision_on.present? }
  validate :start_date_must_be_before_the_revision, if: -> { revision_on.present? }

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
    AcademicYear.where(id: academic_year_ids).order(duration: :desc)
  end

  def duration
    start_date...end_date
  end

private

  def academic_year_ids_must_not_be_empty
    return true unless academic_year_ids.empty?

    errors.add(:academic_year_ids, :blank)
  end

  def academic_year_ids_must_be_eligible
    return if eligible_academic_year_ids.nil?

    selected_ids = Array(academic_year_ids).compact_blank.map(&:to_s)
    return if (selected_ids - eligible_academic_year_ids.map(&:to_s)).empty?

    errors.add(:academic_year_ids, :inclusion)
  end

  # A revision starts a replacement partnership today, so an end date today or
  # earlier would leave it with no days at all (and an impossible duration for
  # Postgres to store).
  def end_date_must_be_after_the_replacement_start
    return if end_date.blank? || end_date > revision_on

    errors.add(:end_date, :must_be_after_today, date: revision_on.to_fs(:govuk))
  end

  # A revision only carries the partnership types from today, so the start date
  # it is given has to leave the current record at least one day to end on.
  def start_date_must_be_before_the_revision
    return if start_date.blank? || start_date < revision_on

    errors.add(:start_date, :must_be_before_today, date: revision_on.to_fs(:govuk))
  end
end
