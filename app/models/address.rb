# == Schema Information
#
# Table name: addresses
#
#  id                 :uuid             not null, primary key
#  address_line_1     :string           not null
#  address_line_2     :string
#  address_line_3     :string
#  county             :string
#  discarded_at       :datetime
#  effective_end_date :date
#  latitude           :decimal(10, 6)
#  longitude          :decimal(10, 6)
#  postcode           :string           not null
#  town_or_city       :string           not null
#  types              :string           default([]), is an Array
#  uprn               :string(15)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  provider_id        :uuid             not null
#
# Indexes
#
#  index_addresses_on_created_at   (created_at)
#  index_addresses_on_provider_id  (provider_id)
#
# Foreign Keys
#
#  fk_rails_...  (provider_id => providers.id)
#
class Address < ApplicationRecord
  self.implicit_order_column = :created_at
  include Discard::Model
  include SaveAsTemporary

  ADDRESS_TYPES = ["trading", "registered", "location"].freeze

  belongs_to :provider

  validates :address_line_1, presence: true, length: { maximum: 255 }
  validates :address_line_2, length: { maximum: 255 }, allow_blank: true
  validates :address_line_3, length: { maximum: 255 }, allow_blank: true
  validates :town_or_city, presence: true, length: { maximum: 255 }
  validates :county, length: { maximum: 255 }, allow_blank: true
  validates :postcode, presence: true, postcode: true
  validate :types_are_valid

  audited associated_with: :provider, except: [:provider_id]

  validates :uprn, length: { maximum: 15 }

private

  def types_are_valid
    return true if types.blank?

    errors.add(:types, "Address types invalid") unless (types - ADDRESS_TYPES).empty?
  end
end
