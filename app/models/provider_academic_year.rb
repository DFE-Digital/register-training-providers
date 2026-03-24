# == Schema Information
#
# Table name: provider_academic_years
#
#  id               :uuid             not null, primary key
#  discarded_at     :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  academic_year_id :uuid             not null
#  provider_id      :uuid             not null
#
# Indexes
#
#  index_provider_academic_years_on_academic_year_id  (academic_year_id)
#  index_provider_academic_years_on_provider_id       (provider_id)
#
# Foreign Keys
#
#  fk_rails_...  (academic_year_id => academic_years.id)
#  fk_rails_...  (provider_id => providers.id)
#
class ProviderAcademicYear < ApplicationRecord
  self.implicit_order_column = :created_at
  belongs_to :provider
  belongs_to :academic_year
  include Discard::Model

  audited except: [:provider_id, :academic_year_id]
end
