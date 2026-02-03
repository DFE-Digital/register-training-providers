# == Schema Information
#
# Table name: academic_cycles
#
#  id         :uuid             not null, primary key
#  duration   :daterange
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_academic_cycles_on_duration  (duration)
#
class AcademicCycle < ApplicationRecord
  self.implicit_order_column = :duration

  has_many :partnership_academic_cycles, dependent: :destroy
  has_many :partnerships, through: :partnership_academic_cycles

  def current?
    duration.cover?(Time.zone.today)
  end

  def next?
    duration.include?(Time.zone.today + 1.year)
  end

  def last?
    duration.include?(Time.zone.today - 1.year)
  end

  def self.for_year(year)
    start_date = Date.new(year, 8, 1)
    where("duration @> ?::date", start_date).first
  end
end
