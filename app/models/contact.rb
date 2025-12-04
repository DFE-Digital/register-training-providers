# == Schema Information
#
# Table name: contacts
#
#  id               :uuid             not null, primary key
#  discarded_at     :datetime
#  email            :string           not null
#  first_name       :string           not null
#  last_name        :string           not null
#  telephone_number :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  provider_id      :uuid             not null
#
# Indexes
#
#  index_contacts_on_created_at             (created_at)
#  index_contacts_on_discarded_at           (discarded_at)
#  index_contacts_on_email_and_provider_id  (email,provider_id) UNIQUE
#  index_contacts_on_provider_id            (provider_id)
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
  validates :email, uniqueness: { scope: :provider }
  validates :telephone_number, length: { maximum: 255 }, allow_blank: true

  validate do |record|
    EmailFormatValidator.new(record).validate if email.present?
    UkTelephoneNumberFormatValidator.new(record).validate if telephone_number.present?
  end

  audited associated_with: :provider

  def full_name
    "#{first_name} #{last_name}"
  end
end
