# == Schema Information
#
# Table name: api_clients
#
#  id            :uuid             not null, primary key
#  discarded_at  :datetime
#  name          :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  created_by_id :uuid             not null
#
# Indexes
#
#  index_api_clients_on_created_by_and_lower_name  (created_by_id, lower((name)::text))
#  index_api_clients_on_discarded_at               (discarded_at)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id) ON DELETE => cascade
#
class ApiClient < ApplicationRecord
  include Discard::Model
  include SaveAsTemporary

  self.implicit_order_column = "created_at"

  has_many :authentication_tokens, dependent: :destroy
  belongs_to :created_by, class_name: "User"

  validates :name, presence: true

  validates :name,
            uniqueness: {
              scope: :created_by_id,
              case_sensitive: false,
              conditions: -> { kept }
            }

  before_discard do
    revoke_all_active_tokens!
  end

  delegate :expires_at, to: :current_authentication_token

  def current_authentication_token
    authentication_tokens.first
  end

  def revoke_all_active_tokens!
    authentication_tokens.active.find_each(&:revoke!)
  end

  def expire_all_due_tokens!
    authentication_tokens.due_for_expiry.find_each(&:expire!)
  end

  def self.sweep_all_tokens!
    discarded.find_each(&:revoke_all_active_tokens!)
    kept.find_each(&:expire_all_due_tokens!)
  end
end
