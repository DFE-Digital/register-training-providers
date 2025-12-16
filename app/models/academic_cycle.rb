# == Schema Information
#
# Table name: academic_cycles
#
#  id           :uuid             not null, primary key
#  discarded_at :datetime
#  duration     :daterange
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_academic_cycles_on_duration  (duration)
#
class AcademicCycle < ApplicationRecord
  self.implicit_order_column = :duration
  include Discard::Model

  has_many :partnership_academic_cycles, dependent: :destroy
  has_many :partnerships, through: :partnership_academic_cycles

  audited

  def current?
    duration.include?(Time.zone.today)
  end

  def next?
    duration.include?(Time.zone.today + 1.year)
  end

  def last?
    duration.include?(Time.zone.today - 1.year)
  end
end
