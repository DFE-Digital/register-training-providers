# == Schema Information
#
# Table name: partnership_academic_years
#
#  id               :uuid             not null, primary key
#  discarded_at     :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  academic_year_id :uuid             not null
#  partnership_id   :uuid             not null
#
# Indexes
#
#  index_partnership_academic_years_on_academic_year_id  (academic_year_id)
#  index_partnership_academic_years_on_partnership_id    (partnership_id)
#
# Foreign Keys
#
#  fk_rails_...  (academic_year_id => academic_years.id)
#  fk_rails_...  (partnership_id => partnerships.id)
#
class PartnershipAcademicYear < ApplicationRecord
  self.implicit_order_column = :created_at
  include PgSearch::Model
  include Discard::Model

  include SaveAsTemporary

  audited

  belongs_to :partnership
  belongs_to :academic_year
end
