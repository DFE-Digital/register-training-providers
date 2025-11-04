require "csv"

require Rails.root.join("config/environment")

namespace :import do
  desc "Import providers data from CSV file"
  task providers: :environment do
    csv_path = ENV.fetch("CSV", nil)
    unless File.exist?(csv_path)
      puts "CSV file not found at #{csv_path}"
      exit 1
    end

    puts "Importing providers from #{csv_path}..."

    invalid_count = 0
    valid_count = 0

    accreditation_statuses_map = {
      "Accredited Provider": :accredited,
      "Training Partner": :unaccredited
    }

    CSV.foreach(csv_path, headers: true) do |row|
      code = row["Provider code"]
      provider = Provider.find_or_initialize_by(code:)
      provider.operating_name = row["Operating name"]
      provider.legal_name = row["Accredited entity"]

      errors_to_add = []

      ukprn = row["UKPRN"]
      if ukprn == "Not found"
        ukprn = 0000_0000
        errors_to_add << { attribute: :ukprn, message: "Not found" }
      end

      provider.ukprn = ukprn
      provider.urn = row["URN"]

      accreditation_status = accreditation_statuses_map[row["Accreditation type"].to_sym]

      provider.accreditation_status = accreditation_status

      provider_type = row["Provider type"].downcase
      provider.provider_type = provider_type

      number = row["Accreditation ID"]

      if number.present?
        provider.accreditations.find_or_initialize_by(number:) do |accreditation|
          accreditation.start_date = row["Start date"]
        end
      end

      provider.valid?

      errors_to_add.each do |error|
        provider.errors.add(error[:attribute], error[:message])
      end
      provider.seed_data_with_issues = provider.errors.any?

      provider.seed_data_notes = {
        row_imported: row.to_h,
        errors: provider.errors.to_hash
      }

      if provider.save(validate: false)
        valid_count += 1
      else
        invalid_count += 1
      end
    rescue StandardError => e
      invalid_count += 1
      puts "Failed to import row #{row.inspect}: #{e.message}"
    end

    puts "#{valid_count}/#{valid_count + invalid_count}  providers was imported."
  end
end
