require Rails.root.join("config/environment")

namespace :example_data do
  desc "Create personas"
  task generate: :environment do
    raise "THIS TASK CANNOT BE RUN IN PRODUCTION" if Rails.env.production?

    SeedPersonas.call(include_system_admin: true)

    ["generate:academic_years",
     "import:providers",
     "import:partnerships",
     "generate:contacts",].each do |task|
      Rake::Task[task].reenable
      Rake::Task[task].invoke
    end
  end
end
