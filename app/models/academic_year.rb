# == Schema Information
#
# Table name: academic_years
#
#  id         :uuid             not null, primary key
#  duration   :daterange
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_academic_years_on_duration  (duration)
#
class AcademicYear < ApplicationRecord
  self.implicit_order_column = :duration

  has_many :partnership_academic_years, dependent: :destroy
  has_many :partnerships, through: :partnership_academic_years

  has_many :provider_academic_years, dependent: :destroy
  has_many :providers, through: :provider_academic_years

  def current?
    duration.cover?(Time.zone.today)
  end

  def next?
    duration.include?(Time.zone.today + 1.year)
  end

  def last?
    duration.include?(Time.zone.today - 1.year)
  end

  def start_year
    duration.begin.year
  end

  def end_year
    duration.end.year
  end

  def self.start_date_for(year)
    Date.new(year, 8, 1)
  end

  def self.covering_dates(dates)
    dates = Array(dates)
    return none if dates.blank?

    where("duration @> ANY (ARRAY[?]::date[])", dates)
  end

  def self.for_year(year)
    start_date = start_date_for(year)
    covering_dates(start_date).first
  end
end
