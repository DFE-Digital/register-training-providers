require Rails.root.join("config/environment")

namespace :generate do
  desc "Generate example accreditation data for providers"
  task partnerships: :environment do
    raise "THIS TASK CANNOT BE RUN IN PRODUCTION" if Rails.env.production?

    generator = Generators::Partnerships.call(percentage: 0.5)

    puts "Generated #{generator.partnerships_created} partnerships"
    puts "for #{generator.total_training_partners} training partners"
  end
end
