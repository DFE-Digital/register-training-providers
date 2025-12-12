# == Schema Information
#
# Table name: partnership_academic_cycles
#
#  id                :bigint           not null, primary key
#  discarded_at      :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  academic_cycle_id :uuid             not null
#  partnership_id    :uuid             not null
#
# Indexes
#
#  index_partnership_academic_cycles_on_academic_cycle_id  (academic_cycle_id)
#  index_partnership_academic_cycles_on_partnership_id     (partnership_id)
#
# Foreign Keys
#
#  fk_rails_...  (academic_cycle_id => academic_cycles.id)
#  fk_rails_...  (partnership_id => partnerships.id)
#
class PartnershipAcademicCycle < ApplicationRecord
  self.implicit_order_column = :created_at
  include PgSearch::Model
  include Discard::Model

  include SaveAsTemporary

  audited

  belongs_to :partnership, dependent: :destroy
  belongs_to :academic_cycle, dependent: :destroy
end
