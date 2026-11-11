# == Schema Information
#
# Table name: partnership_types
#
#  id               :uuid             not null, primary key
#  discarded_at     :datetime
#  partnership_type :string           not null
#  source           :string           default("user"), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  partnership_id   :uuid             not null
#
# Indexes
#
#  index_partnership_types_on_partnership_id_and_partnership_type  (partnership_id,partnership_type) UNIQUE WHERE (discarded_at IS NULL)
#
# Foreign Keys
#
#  fk_rails_...  (partnership_id => partnerships.id) ON DELETE => cascade
#
class PartnershipType < ApplicationRecord
  include PartnershipTypeEnum
  include Discard::Model

  self.implicit_order_column = :created_at

  audited

  belongs_to :partnership

  scope :used_for, lambda { |accredited_provider_id:, provider_id:|
    kept
      .joins(:partnership)
      .where(partnerships: { accredited_provider_id:, provider_id: })
      .merge(Partnership.kept.current_or_scheduled)
  }

  def self.used_between(accredited_provider_id:, provider_id:)
    used_for(accredited_provider_id:, provider_id:).distinct.pluck(:partnership_type)
  end

  validates :partnership_type, presence: true
  validates :partnership_type,
            uniqueness: { scope: :partnership_id, conditions: -> { kept } }

  validate :partnership_type_must_not_be_used_by_another_partnership
  validate :placement_requires_school_partner

private

  def partnership_type_must_not_be_used_by_another_partnership
    return if partnership.blank? || partnership_type.blank?

    scope = self.class
      .used_for(**partner_pair)
      .where(partnership_type:)

    scope = scope.where.not(partnership_id: partnership.id) if partnership.persisted?

    errors.add(:partnership_type, :already_used) if scope.exists?
  end

  def placement_requires_school_partner
    return unless placement?
    return if partnership.blank?
    return if partnership.provider&.school?

    errors.add(:partnership_type, :placement_requires_school)
  end

  def partner_pair
    {
      accredited_provider_id: partnership.accredited_provider_id || partnership.accredited_provider&.id,
      provider_id: partnership.provider_id || partnership.provider&.id
    }
  end
end
