# == Schema Information
#
# Table name: provider_changes
#
#  id             :uuid             not null, primary key
#  attribute_name :string           not null
#  effective_on   :date             not null
#  error_message  :text
#  processed_at   :datetime
#  status         :string           default("pending"), not null
#  value          :jsonb            not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  created_by_id  :uuid
#  provider_id    :uuid             not null
#
# Indexes
#
#  idx_on_provider_id_attribute_name_effective_on_d4e00b3792  (provider_id,attribute_name,effective_on)
#  index_provider_changes_on_created_by_id                    (created_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (provider_id => providers.id)
#
class ProviderChange < ApplicationRecord
  self.implicit_order_column = :created_at

  belongs_to :provider

  enum :status, {
    pending: "pending",
    processing: "processing",
    completed: "completed",
    failed: "failed"
  }

  validates :attribute_name, presence: true
  validates :value, presence: true
  validates :effective_on, presence: true

  scope :for_attribute, ->(attribute) {
    where(attribute_name: attribute)
  }

  scope :history, -> {
    order(effective_on: :desc, created_at: :desc)
  }
end
