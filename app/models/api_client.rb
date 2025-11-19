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

  self.implicit_order_column = "created_at"

  validates :name, presence: true, uniqueness: { case_sensitive: false }
end
