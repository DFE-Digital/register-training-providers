# == Schema Information
#
# Table name: api_clients
#
#  id           :uuid             not null, primary key
#  discarded_at :datetime
#  name         :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_api_clients_on_discarded_at  (discarded_at)
#  index_api_clients_on_lower_name    (lower((name)::text)) UNIQUE
#
class ApiClient < ApplicationRecord
  include Discard::Model

  has_many :authentication_tokens, dependent: :destroy

  before_discard do
    authentication_tokens.active.each(&:revoke!)
  end

  self.implicit_order_column = "created_at"

  has_many :authentication_tokens, dependent: :destroy

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  before_discard do
    revoke_all_active_tokens!
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
