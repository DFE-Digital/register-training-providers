# == Schema Information
#
# Table name: providers
#
#  id                   :bigint           not null, primary key
#  accreditation_status :string           not null
#  archived_at          :datetime
#  code                 :string(3)        not null
#  discarded_at         :datetime
#  legal_name           :string
#  operating_name       :string           not null
#  provider_type        :string           not null
#  ukprn                :string(8)        not null
#  urn                  :string(6)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
# Indexes
#
#  index_providers_on_accreditation_status  (accreditation_status)
#  index_providers_on_archived_at           (archived_at)
#  index_providers_on_code                  (code) UNIQUE
#  index_providers_on_discarded_at          (discarded_at)
#  index_providers_on_legal_name            (legal_name)
#  index_providers_on_provider_type         (provider_type)
#  index_providers_on_ukprn                 (ukprn)
#  index_providers_on_urn                   (urn)
#
class Provider < ApplicationRecord
  include Discard::Model
  include SaveAsTemporary

  has_many :temporary_records, foreign_key: :created_by, dependent: :destroy

  audited

  include ProviderTypeEnum
  include AccreditationStatusEnum

  scope :order_by_operating_name, -> { order(:operating_name) }

  validates :provider_type, presence: true, provider_type: true

  include AccreditationStatusValidator

  validates :operating_name, presence: true
  validates :ukprn, presence: true, format: { with: /\A[0-9]{8}\z/ }
  validates :code, presence: true, uniqueness: { case_sensitive: false }, format: { with: /\A[A-Z0-9]{3}\z/i }
  validates :urn, presence: true, format: { with: /\A[0-9]{5,6}\z/ },
                  if: :requires_urn?

  validate :school_accreditation_status

  before_save :upcase_code

  def upcase_code
    self.code = code.upcase
  end

  def requires_urn?
    [:school, :scitt].include?(provider_type&.to_sym)
  end

  def archive!
    update!(archived_at: Time.zone.now.utc)
  end

  def archived?
    archived_at.present?
  end

  def not_archived?
    !archived?
  end

  def restore!
    update!(archived_at: nil)
  end

private

  def school_accreditation_status
    if school? && accredited?
      errors.add(:provider_type, :invalid_accreditation_status)
      errors.add(:accreditation_status, :invalid_provider_type)
    end
  end
end
