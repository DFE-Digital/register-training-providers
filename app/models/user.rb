# == Schema Information
#
# Table name: users
#
#  id                :integer          not null, primary key
#  dfe_sign_in_uid   :string
#  email             :string           not null
#  first_name        :string           not null
#  last_name         :string           not null
#  last_signed_in_at :datetime
#  discarded_at      :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_users_on_discarded_at  (discarded_at)
#  index_users_on_email         (email) UNIQUE
#

class User < ApplicationRecord
  include Discard::Model
  include SaveAsTemporary

  has_many :temporary_records, foreign_key: :created_by, dependent: :destroy

  audited

  before_validation :sanitise_email

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: true

  validate do |record|
    DfEEmailFormatValidator.new(record).validate if email.present?
  end

  scope :order_by_first_then_last_name, -> { order(:first_name, :last_name) }

  def name
    "#{first_name} #{last_name}"
  end

  def load_temporary(record_class, purpose:, id: nil, reset: false)
    clear_temporary(record_class, purpose:) if reset

    record_type = record_class.name
    record = temporary_records.find_by(record_type: record_type, purpose: purpose)

    if record&.expired?
      temporary_records.where(record_type: record_type, purpose: purpose).delete_all
      return record_class.new
    end

    if id.present?
      existing_record = record_class.find(id)
      existing_record.assign_attributes(record.rehydrate.attributes.except("id")) if record.present?
      existing_record
    else
      record&.rehydrate || record_class.new
    end
  end

  def clear_temporary(record_class, purpose:)
    temporary_records.where(record_type: record_class.name, purpose: purpose).delete_all
  end

private

  def sanitise_email
    self.email = email.gsub(/\s+/, "").downcase unless email.nil?
  end
end
