# == Schema Information
#
# Table name: provider_academic_cycles
#
#  id                :uuid             not null, primary key
#  discarded_at      :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  academic_cycle_id :uuid             not null
#  provider_id       :uuid             not null
#
# Indexes
#
#  index_provider_academic_cycles_on_academic_cycle_id  (academic_cycle_id)
#  index_provider_academic_cycles_on_provider_id        (provider_id)
#
# Foreign Keys
#
#  fk_rails_...  (academic_cycle_id => academic_cycles.id)
#  fk_rails_...  (provider_id => providers.id)
#
class ProviderAcademicYear < ApplicationRecord
  self.implicit_order_column = :created_at
  belongs_to :provider
  belongs_to :academic_year
  include Discard::Model

  audited except: [:provider_id, :academic_year_id]
end
