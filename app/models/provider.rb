class Provider < ApplicationRecord
  include Discard::Model
  include SaveAsTemporary

  has_many :temporary_records, foreign_key: :created_by, dependent: :destroy

  audited

  enum :provider_type, hei: "hei", scitt: "scitt", school: "school", other: "other"
  enum :accreditation_status, accredited: "accredited", unaccredited: "unaccredited"

  scope :order_by_operating_name, -> { order(:operating_name) }

  validates :provider_type, presence: true
  validates :accreditation_status, presence: true
  validates :operating_name, presence: true
  validates :ukprn, presence: true, format: { with: /\A[0-9]{8}\z/ }
  validates :code, presence: true, uniqueness: { case_sensitive: false }, format: { with: /\A[A-Z0-9]{3}\z/i }
  validates :urn, presence: true, format: { with: /\A[0-9]{5,6}\z/ },
                  if: -> { [:school, :scitt].include?(provider_type&.to_sym) }

  validate :school_accreditation_status

  def code=(cde)
    self[:code] = cde.to_s.upcase
  end

private

  def school_accreditation_status
    if school? && accredited?
      errors.add(:provider_type, :invalid_accreditation_status)
      errors.add(:accreditation_status, :invalid_provider_type)
    end
  end
end
