# == Schema Information
#
# Table name: accreditations
#
#  id          :bigint           not null, primary key
#  end_date    :date
#  number      :string           not null
#  start_date  :date             not null
#  uuid        :uuid             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  provider_id :bigint           not null
#
# Indexes
#
#  index_accreditations_on_end_date     (end_date)
#  index_accreditations_on_number       (number)
#  index_accreditations_on_provider_id  (provider_id)
#  index_accreditations_on_start_date   (start_date)
#  index_accreditations_on_uuid         (uuid) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (provider_id => providers.id)
#
class Accreditation < ApplicationRecord
  include UuidIdentifiable

  belongs_to :provider

  audited

  validates :number, presence: true
  validates :start_date, presence: true

  scope :current, -> { where('start_date <= ? AND (end_date IS NULL OR end_date >= ?)', Date.current, Date.current) }
  scope :order_by_start_date, -> { order(:start_date) }

  after_save :sync_provider_accreditation_status
  after_destroy :sync_provider_accreditation_status_on_destroy
  after_touch :sync_provider_accreditation_status

private

  def sync_provider_accreditation_status
    provider.sync_accreditation_status!
  end

  def sync_provider_accreditation_status_on_destroy
    # Use provider_id directly since the association might not be reliable after destroy
    return unless provider_id.present?
    
    provider_record = Provider.find_by(id: provider_id)
    provider_record&.sync_accreditation_status!
  end
end
