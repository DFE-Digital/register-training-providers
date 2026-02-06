require "roo"
require_relative "import_tabular_helper"

namespace :import do
  extend ImportTabularHelper

  desc "Import providers from CSV or XLSX"
  task providers: :environment do
    file_paths = if ENV["DATASET"].present? && ENV["DATASET"] == "pre-2024"
                   ["lib/data/pre-2024/unaccredited_providers_filtered_unmatched_accredited_providers.csv",
                    "lib/data/pre-2024/unaccredited_providers_filtered.csv"]
                 else
                   [
                     "lib/data/2024/accredited_providers_amended_accreditation_start_date.csv",
                     "lib/data/2024/accredited_providers_amended_legal_name.csv",
                     "lib/data/2024/accredited_providers_swapped.csv",
                     "lib/data/2024/accredited_providers_unmatched_unaccredited_providers.csv",
                     "lib/data/2024/accredited_providers.csv",
                     "lib/data/2024/unaccredited_providers_filtered_unmatched_accredited_providers.csv",
                     "lib/data/2024/unaccredited_providers_filtered.csv",
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
    file_path = if ENV["DATASET"].present? && ENV["DATASET"] == "pre-2024"
                  "lib/data/pre-2024/provider-partnerships_filtered.csv"
                else
                  "lib/data/2024/provider-partnerships_filtered.csv"
                end

    import_file(
      file_path: Rails.root.join(file_path).to_s,
      importer_class: DataImporter::PartnershipService
    )
  end
end
