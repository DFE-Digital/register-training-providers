require Rails.root.join("config/environment")

namespace :generate do
  desc "Generate example accreditation data for providers"
  task academic_cycles: :environment do
    years = 2019..2030

    existing_academic_cycles = AcademicCycle.all.map { |x| x.duration.begin.year }

    ActiveRecord::Base.transaction do
      (years.to_a - existing_academic_cycles).each do |year|
        AcademicCycle.create(duration: Time.zone.local(year, 8, 1)...Time.zone.local(year + 1, 7, 31))
      end
    end

    puts final_message(years.to_a - existing_academic_cycles)
  end
end

def final_message(years)
  return "No academic cycles to generate" if years.empty?

  "Academic cycles generated for #{years.join(", ")}"
end
