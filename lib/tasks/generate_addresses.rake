require Rails.root.join("config/environment")

namespace :generate do
  desc "Generate example address data for providers"
  task addresses: :environment do
    raise "THIS TASK CANNOT BE RUN IN PRODUCTION" if Rails.env.production?

    generator = Generators::Addresses.call(percentage: 0.5)

    puts "Generated addresses for #{generator.providers_addressed}"
    puts "out of #{generator.total_addressable} addressable providers"
  end
end
