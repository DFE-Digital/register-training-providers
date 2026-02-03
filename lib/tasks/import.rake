require "roo"
require_relative "import_tabular_helper"

namespace :import do
  extend ImportTabularHelper

  desc "Import providers from CSV or XLSX"
  task providers: :environment do
    file_paths = if ENV["FILE"].present?
                   [ENV["FILE"]]
                 else
                   [
                     "lib/data/accredited_providers_swapped.csv",
                     "lib/data/accredited_providers_amended_accreditation_start_date.csv",
                     "lib/data/accredited_providers_amended_legal_name.csv",
                     "lib/data/accredited_providers_unmatched_unaccredited_providers.csv",
                     "lib/data/accredited_providers.csv",
                     "lib/data/unaccredited_providers_unmatched_accredited_providers.csv",
                     "lib/data/unaccredited_providers.csv",
                   ]
                 end
    file_paths.each do |path|
      file_path = Rails.root.join(path).to_s
      import_file(
        file_path: file_path,
        importer_class: DataImporter::ProviderService
      )
    end
  end

  desc "Import partnerships from CSV or XLSX"
  task partnerships: :environment do
    file_path = ENV["FILE"] ||
      Rails.root.join("lib/data/provider-partnerships.csv").to_s

    import_file(
      file_path: file_path,
      importer_class: DataImporter::PartnershipService
    )
  end
end
