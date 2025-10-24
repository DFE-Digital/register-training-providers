require Rails.root.join("config/environment")

namespace :generate do
  desc "Generate example contact data for providers"
  task contacts: :environment do
    raise "THIS TASK CANNOT BE RUN IN PRODUCTION" if Rails.env.production?

    generator = Generators::Contacts.call(percentage: 0.5)

    puts "Generated contacts for #{generator.providers_contacted}"
    puts "out of #{generator.total_contactable} contactable providers"
  end
end
