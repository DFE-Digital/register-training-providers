# == Schema Information
#
# Table name: partnerships
#
#  id                     :uuid             not null, primary key
#  discarded_at           :datetime
#  duration               :daterange
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  accredited_provider_id :uuid             not null
#  provider_id            :uuid             not null
#
# Indexes
#
#  index_partnerships_on_accredited_provider_id  (accredited_provider_id)
#  index_partnerships_on_provider_id             (provider_id)
#
# Foreign Keys
#
#  fk_rails_...  (accredited_provider_id => providers.id)
#  fk_rails_...  (provider_id => providers.id)
#
class Partnership < ApplicationRecord
  self.implicit_order_column = :created_at
  include PgSearch::Model
  include Discard::Model

  include SaveAsTemporary

  audited except: [:provider_id, :accredited_provider_id]

  belongs_to :provider
  belongs_to :accredited_provider, class_name: "Provider"
  has_many :partnership_academic_cycles, dependent: :destroy
  has_many :academic_cycles, through: :partnership_academic_cycles

  scope :ordered_by_partner_and_date, ->(viewing_provider) {
    joins(
      sanitize_sql_array([
        "INNER JOIN providers AS partner ON partner.id = CASE
          WHEN partnerships.accredited_provider_id = ?
          THEN partnerships.provider_id
          ELSE partnerships.accredited_provider_id
        END",
        viewing_provider.id
      ])
    ).order("partner.operating_name ASC", "lower(partnerships.duration) ASC")
  }

  def other_partner(partner)
    return accredited_provider if partner == provider

    provider
  end
end
