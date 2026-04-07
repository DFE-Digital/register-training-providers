require Rails.root.join("config/environment")

namespace :generate do
  desc "Generate academic years"
  task academic_years: :environment do
    required_academic_years = (2019..2030).to_a
    existing_academic_years = AcademicYear.all.map { |ac| ac.duration.begin.year }

    (required_academic_years - existing_academic_years).each do |year|
      AcademicYear.create({ duration: Date.new(year, 8, 1)..Date.new(year + 1, 7, 31) })
    end

    if (required_academic_years - existing_academic_years).empty?
      puts "No academic years to generate"
    else
      puts "Generated academic years for #{(required_academic_years - existing_academic_years).join(", ")}"
    end
  end
end
