# == Schema Information
#
# Table name: providers
#
#  id                   :bigint           not null, primary key
#  accreditation_status :string           not null
#  archived_at          :datetime
#  code                 :citext           not null
#  discarded_at         :datetime
#  legal_name           :string
#  operating_name       :string           not null
#  provider_type        :string           not null
#  searchable           :tsvector
#  ukprn                :string(8)        not null
#  urn                  :string(6)
#  uuid                 :uuid             not null
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
#  index_providers_on_searchable            (searchable) USING gin
#  index_providers_on_ukprn                 (ukprn)
#  index_providers_on_urn                   (urn)
#  index_providers_on_uuid                  (uuid) UNIQUE
#
class Provider < ApplicationRecord
  include PgSearch::Model
  include Discard::Model

  include SaveAsTemporary
  include UuidIdentifiable

  has_many :temporary_records, foreign_key: :created_by, dependent: :destroy

  audited

  include ProviderTypeEnum
  include AccreditationStatusEnum

  scope :order_by_operating_name, -> { order(:operating_name) }

  validates :provider_type, presence: true, provider_type: true

  include AccreditationStatusValidator

  validates :operating_name, presence: true
  validates :ukprn, presence: true, format: { with: /\A[0-9]{8}\z/ }, length: { is: 8 }
  validates :code, presence: true, uniqueness: true, format: { with: /\A[A-Z0-9]{3}\z/i }, length: { is: 3 }
  validates :urn, presence: true, format: { with: /\A[0-9]{5,6}\z/ }, length: { in: 5..6 },
                  if: :requires_urn?

  validate :school_accreditation_status

  before_save :upcase_code
  before_save :update_searchable

  pg_search_scope :search,
                  against: %i[operating_name urn ukprn legal_name],
                  using: {
                    tsearch: {
                      prefix: true,
                      tsvector_column: "searchable",
                    },
                  }

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

  def update_searchable
    ts_vector_value = [
      operating_name,
      operating_name_normalised,
      urn,
      ukprn,
      legal_name,
      legal_name_normalised,
    ].join(" ")

    to_tsvector = Arel::Nodes::NamedFunction.new(
      "TO_TSVECTOR", [
        Arel::Nodes::Quoted.new("pg_catalog.simple"),
        Arel::Nodes::Quoted.new(ts_vector_value),
      ]
    )

    self.searchable =
      ActiveRecord::Base
        .connection
        .execute(Arel::SelectManager.new.project(to_tsvector).to_sql)
        .first
        .values
        .first
  end

  def operating_name_normalised
    ReplaceAbbreviation.call(string: StripPunctuation.call(string: operating_name))
  end

  def legal_name_normalised
    ReplaceAbbreviation.call(string: StripPunctuation.call(string: legal_name))
  end
end
