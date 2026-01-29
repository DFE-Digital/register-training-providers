require "roo"
require_relative "import_xlsx_helper"

namespace :import do
  extend ImportXlsxHelper

  desc "Import providers from XLSX"
  task providers_xlsx: :environment do
    file_path = ENV["XLSX"] ||
      Rails.root.join("lib/data/provider_seed_report_v_4.0_without_pii.xlsx").to_s

    import_xlsx(
      file_path: file_path,
      sheet_name: "providers",
      importer_class: XlsxRowImporter::ProviderService
    )
  end

  desc "Import partnerships from XLSX"
  task partnerships_xlsx: :environment do
    file_path = ENV["XLSX"] ||
      Rails.root.join("lib/data/provider_seed_report_v_4.0_without_pii.xlsx").to_s

    import_xlsx(
      file_path: file_path,
      sheet_name: "provider-partnerships",
      importer_class: XlsxRowImporter::PartnershipService
    )
  end
end
