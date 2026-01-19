require "roo"

namespace :import do
  desc "Import providers data from XLSX file"
  task providers_xlsx: :environment do
    xlsx_path = ENV["XLSX"] || Rails.root.join("lib/data/provider_seed_report_v_2.2_without_pii.xlsx").to_s

    unless xlsx_path && File.exist?(xlsx_path)
      puts "XLSX file not found at #{xlsx_path}"
      exit 1
    end

    puts "Importing providers from #{xlsx_path}..."

    xlsx = Roo::Excelx.new(xlsx_path)

    sheet = xlsx.sheet("provider_report")

    headers = sheet.row(1).map(&:to_s)

    valid_count = 0
    invalid_count = 0

    sheet.each_row_streaming(pad_cells: true, offset: 1) do |row|
      row_hash = headers.zip(row.map do |c|
        c&.value
      end).to_h

      next if row_hash.values.all?(&:nil?)

      ActiveRecord::Base.transaction do
        ProviderXlsxRowImporter.call(row_hash)
        valid_count += 1
      end
    rescue StandardError => e
      invalid_count += 1
      Rails.logger.error("Failed row: #{row_hash.inspect}")
      Rails.logger.error(e.message)
    end

    puts "#{valid_count}/#{valid_count + invalid_count} providers imported"
  end
end
