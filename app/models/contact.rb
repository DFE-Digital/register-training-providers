# == Schema Information
#
# Table name: contacts
#
#  id               :uuid             not null, primary key
#  discarded_at     :datetime
#  email            :string           not null
#  first_name       :string           not null
#  last_name        :string           not null
#  telephone_number :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  provider_id      :uuid             not null
#
# Indexes
#
#  index_contacts_on_created_at    (created_at)
#  index_contacts_on_discarded_at  (discarded_at)
#  index_contacts_on_provider_id   (provider_id)
#
# Foreign Keys
#
#  fk_rails_...  (provider_id => providers.id)
#
class Contact < ApplicationRecord
  self.implicit_order_column = :created_at
  include Discard::Model
  include SaveAsTemporary

  belongs_to :provider

  validates :first_name, presence: true, length: { maximum: 255 }
  validates :last_name, presence: true, length: { maximum: 255 }
  validates :email, presence: true, length: { maximum: 255 }
  validates :telephone_number, presence: true, length: { maximum: 255 }

  validate do |record|
    EmailFormatValidator.new(record).validate if email.present?
  end

  audited
end
