require Rails.root.join("config/environment")

namespace :generate do
  desc "Generate example accreditation data for providers"
  task accreditations: :environment do
    raise "THIS TASK CANNOT BE RUN IN PRODUCTION" if Rails.env.production?

    generator = Generators::Accreditations.call(percentage: 0.5)

    puts "Generated accreditations for #{generator.providers_accredited}"
    puts "out of #{generator.total_accreditable} accreditable providers"
  end
end
