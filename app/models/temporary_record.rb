# == Schema Information
#
# Table name: temporary_records
#
#  id          :bigint           not null, primary key
#  created_by  :uuid
#  data        :jsonb            not null
#  expires_at  :datetime         not null
#  purpose     :string           default(NULL), not null
#  record_type :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_temporary_records_on_created_by                      (created_by)
#  index_temporary_records_on_created_by_record_type_purpose  (created_by,record_type,purpose) UNIQUE
#  index_temporary_records_on_expires_at                      (expires_at)
#
# Foreign Keys
#
#  fk_rails_...  (created_by => users.id)
#
class TemporaryRecord < ApplicationRecord
  belongs_to :creator, class_name: "User", foreign_key: :created_by

  enum :purpose, {
    check_your_answers: "check_your_answers"
  }

  scope :expired, -> { where(expires_at: ..Time.current) }

  validates :record_type, presence: true
  validates :expires_at, presence: true
  validates :purpose, uniqueness: { scope: [:created_by, :record_type] }

  def expired?
    expires_at <= Time.current
  end

  def rehydrate
    record_type.constantize.new(**safe_data)
  end

private

  def safe_data
    # Start with database attributes
    safe_attrs = record_type.constantize.attribute_names.index_with { |attr| data[attr] }

    # Add any other keys from data that might be virtual attributes
    data.each do |key, value|
      safe_attrs[key] = value unless safe_attrs.key?(key)
    end

    safe_attrs
  end
end
