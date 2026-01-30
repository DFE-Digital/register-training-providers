require "roo"
require_relative "import_tabular_helper"

namespace :import do
  extend ImportTabularHelper

  desc "Import providers from CSV or XLSX"
  task providers: :environment do
    file_path = ENV["FILE"] ||
      Rails.root.join("lib/data/providers.csv").to_s

    import_file(
      file_path: file_path,
      importer_class: DataImporter::ProviderService
    )
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
