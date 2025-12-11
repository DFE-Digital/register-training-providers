# == Schema Information
#
# Table name: accreditations
#
#  id           :uuid             not null, primary key
#  discarded_at :datetime
#  end_date     :date
#  number       :string           not null
#  start_date   :date             not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  provider_id  :uuid             not null
#
# Indexes
#
#  index_accreditations_on_discarded_at  (discarded_at)
#  index_accreditations_on_end_date      (end_date)
#  index_accreditations_on_number        (number)
#  index_accreditations_on_provider_id   (provider_id)
#  index_accreditations_on_start_date    (start_date)
#
# Foreign Keys
#
#  fk_rails_...  (provider_id => providers.id)
#
class Accreditation < ApplicationRecord
  self.implicit_order_column = :created_at
  include Discard::Model
  include SaveAsTemporary

  belongs_to :provider

  audited associated_with: :provider, except: [:provider_id]

  validates :number, presence: true, accreditation_number: true
  validates :start_date, presence: true

  scope :current, -> { where("start_date <= ? AND (end_date IS NULL OR end_date >= ?)", Date.current, Date.current) }
  scope :order_by_start_date, -> { order(:start_date) }

  after_discard :sync_provider_accreditation_status_on_destroy
  after_save :sync_provider_accreditation_status
  after_touch :sync_provider_accreditation_status

private

  def sync_provider_accreditation_status
    provider.sync_accreditation_status!
  end

  def sync_provider_accreditation_status_on_destroy
    # Use provider_id directly since the association might not be reliable after destroy
    return if provider_id.blank?

    provider_record = Provider.find_by(id: provider_id)
    provider_record&.sync_accreditation_status!
  end
end
