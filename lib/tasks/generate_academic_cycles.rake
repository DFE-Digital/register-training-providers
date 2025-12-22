require Rails.root.join("config/environment")

namespace :generate do
  desc "Generate academic cycles"
  task academic_cycles: :environment do
    required_academic_cycles = (2009..2030).to_a
    existing_academic_cycles = AcademicCycle.all.map { |ac| ac.duration.begin.year }

    (required_academic_cycles - existing_academic_cycles).each do |year|
      AcademicCycle.create({ duration: Date.new(year, 8, 1)...Date.new(year + 1, 7, 31) })
    end

    if (required_academic_cycles - existing_academic_cycles).empty?
      puts "No academic cycles to generate"
    else
      puts "Generated academic cycles for #{(required_academic_cycles - existing_academic_cycles).join(", ")}"
    end
  end
end
