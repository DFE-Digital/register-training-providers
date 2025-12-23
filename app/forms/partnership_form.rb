class PartnershipForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations::Callbacks
  include GovukDateValidation
  include GovukDateComponents

  has_date_components :start_date, :end_date

  attr_accessor :academic_cycle_ids

  attribute :provider_id, :string
  attribute :accredited_provider_id, :string

  validates :accredited_provider_id, presence: true
  validates :provider_id, presence: true
  validates :start_date, presence: true
  validate :academic_cycle_ids_must_not_be_empty

  attr_reader :provider, :accredited_provider, :academic_cycles

  def self.from_dates(dates)
    form = new

    new(form.extract_date_components_from(dates))
  end

  def self.model_name
    ActiveModel::Name.new(self, nil, "Dates")
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
      academic_cycles:
    }.compact
  end

  def provider
    Provider.find(provider_id)
  end

  def accredited_provider
    Provider.find(accredited_provider_id)
  end

  def academic_cycles
    AcademicCycle.where(id: academic_cycle_ids)
  end

  def duration
    start_date...end_date
  end

private

  def academic_cycle_ids_must_not_be_empty
    return true unless academic_cycle_ids.empty?

    errors.add(:academic_cycle_ids, :blank)
  end
end
