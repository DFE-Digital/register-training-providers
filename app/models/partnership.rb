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
  has_many :partnership_academic_years, dependent: :destroy
  has_many :academic_years, through: :partnership_academic_years
  has_many :partnership_types

  validate :partnership_types_present

  validate :partnership_types_remain_available, if: -> { persisted? && will_save_change_to_duration? }

  scope :current_or_scheduled, lambda {
    where("upper(duration) IS NULL OR upper(duration) > ?", Time.zone.today)
  }

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

  def apply_default_partnership_type(source: "user")
    partnership_types.build(
      partnership_type: PartnershipTypeEnum::RECRUITMENT,
      source: source
    )
  end

private

  def partnership_types_present
    return if partnership_types.reject(&:discarded?).any?

    errors.add(:partnership_types, :blank)
  end

  def partnership_types_remain_available
    partnership_types.reject(&:discarded?).each do |type|
      next if type.valid?

      type.errors[:partnership_type].each { |message| errors.add(:base, message) }
    end
  end
end
