require Rails.root.join("config/environment")

namespace :seed_data do
  desc "Seed data including personas only on non production and providers"
  task import: :environment do
    unless Rails.env.production?

      SeedPersonas.call(include_system_admin: false)
    end

    ["generate:academic_years",
     "import:providers",
     "import:partnerships"].each do |task|
      Rake::Task[task].reenable
      Rake::Task[task].invoke
    end
  end
end
