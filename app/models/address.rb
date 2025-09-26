# == Schema Information
#
# Table name: addresses
#
#  id             :uuid             not null, primary key
#  address_line_1 :string           not null
#  address_line_2 :string
#  address_line_3 :string
#  county         :string
#  discarded_at   :datetime
#  latitude       :decimal(10, 6)
#  longitude      :decimal(10, 6)
#  postcode       :string           not null
#  town_or_city   :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  provider_id    :uuid             not null
#
# Indexes
#
#  index_addresses_on_postcode     (postcode)
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

  belongs_to :provider

  validates :address_line_1, presence: true
  validates :town_or_city, presence: true
  validates :postcode, presence: true

  audited
end
