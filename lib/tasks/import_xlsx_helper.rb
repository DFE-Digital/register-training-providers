module ImportXlsxHelper
  def import_xlsx(file_path:, sheet_name:, importer_class:)
    raise Errno::ENOENT, "XLSX file not found at #{file_path}" unless File.exist?(file_path)

    puts "Importing from #{file_path}, sheet: #{sheet_name}..."

    xlsx = Roo::Excelx.new(file_path)

    unless xlsx.sheets.include?(sheet_name)
      available = xlsx.sheets.map { |s| "• #{s}" }.join("\n")
      raise ArgumentError,
            "Sheet '#{sheet_name}' not found in #{file_path}.\nAvailable sheets:\n#{available}"
    end

    sheet = xlsx.sheet(sheet_name)
    headers = sheet.row(1).map(&:to_s).freeze

    valid_count = 0
    invalid_count = 0

    sheet.each_row_streaming(pad_cells: true, offset: 1) do |row|
      row_hash = headers.zip(row.map { |c| c&.value }).to_h
      next if row_hash.values.all?(&:nil?)

      begin
        ActiveRecord::Base.transaction do
          importer_class.call(row_hash)
          valid_count += 1
        end
      rescue StandardError => e
        invalid_count += 1
        Rails.logger.error("Failed row: #{row_hash.inspect}")
        Rails.logger.error(e.message)
      end
    end

    total = valid_count + invalid_count
    puts "#{valid_count}/#{total} rows imported for #{sheet_name}"
  end
end
