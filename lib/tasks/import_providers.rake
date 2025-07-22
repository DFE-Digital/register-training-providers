require "csv"

require Rails.root.join("config/environment")

namespace :import do
  desc "Import providers data from CSV file"
  task providers: :environment do
    raise "THIS TASK CANNOT BE RUN IN PRODUCTION" if Rails.env.production?

    csv_path = ENV.fetch("CSV", nil)
    unless File.exist?(csv_path)
      puts "CSV file not found at #{csv_path}"
      exit 1
    end

    puts "Importing providers from #{csv_path}..."

    invalid_count = 0
    valid_count = 0
    CSV.foreach(csv_path, headers: true) do |row|
      provider = Provider.find_or_initialize_by(code: row["code"])
      provider.operating_name = row["operating_name"]
      provider.legal_name = row["legal_name"]
      provider.code = row["code"]
      provider.ukprn = row["ukprn"]
      provider.urn = row["urn"]
      provider.accreditation_status = :unaccredited

      if Provider.provider_types.key?(row["provider_type"])
        provider.provider_type = row["provider_type"]
      else
        puts "Warning: Unknown provider_type '#{row['provider_type']}' for code #{row['code']}"
        next
      end

      if provider.save
        valid_count += 1
      else
        invalid_count += 1
      end
    rescue StandardError => e
      puts "Failed to import row #{row.inspect}: #{e.message}"
    end

    puts "#{valid_count}/#{valid_count + invalid_count} providers was imported."
  end
end
