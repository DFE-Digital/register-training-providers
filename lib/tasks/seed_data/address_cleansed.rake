# lib/tasks/seed_data/address_washing_machine_cleansed.rake
require "roo"
require "write_xlsx"

ADDRESS_FIELD_MAP = {
  "address_line_1" => "address__address_line_1",
  "address_line_2" => "address__address_line_2",
  "address_line_3" => "address__address_line_3",
  "town_or_city" => "address__town_or_city",
  "county" => "address__county",
  "postcode" => "address__postcode"
}.freeze

OS_EXTRA_FIELD_MAP = {
  "uprn" => "address__uprn",
  "latitude" => "address__latitude",
  "longitude" => "address__longitude"
}.freeze

ROW_TYPE_COL     = "row_type".freeze
FOUND_COL        = "found".freeze
MODEL_FIELDS_COL = "model_fields".freeze
OS_FIELDS_COL    = "os_fields".freeze

MODEL_VS_OS_FIELD_COMBOS = [
  ["provider__legal_name",     "organisation_name"],
  ["provider__legal_name",     "address_line_1"],
  ["provider__operating_name", "organisation_name"],
  ["provider__operating_name", "address_line_1"],
  ["address__address_line_1",  "organisation_name"],
  ["address__address_line_1",  "address_line_1"]
].freeze

namespace :seed_data do
  desc "Address washing machine – cleansed output with full traceability"
  task address_cleansed: :environment do
    minor = 0

    xlsx_path =
      ENV["XLSX"] || Rails.root.join("lib/data/provider_seed_report_v_2.#{minor}_without_pii.xlsx").to_s

    output_path =
      Rails.root.join("lib/data/provider_seed_report_v_2.#{minor + 1}_without_pii.xlsx").to_s

    # --------------------------
    # Load input
    # --------------------------
    wb_in    = Roo::Spreadsheet.open(xlsx_path)
    sheet_in = wb_in.sheet("provider_report")

    header = sheet_in.row(1).map(&:to_s)
    header.each_with_index.to_h

    # --------------------------
    # Prepare output workbook
    # --------------------------
    workbook = WriteXLSX.new(output_path)

    provider_sheet              = workbook.add_worksheet("provider_report")
    one_match_from_first_pass   = workbook.add_worksheet("one_match_from_first_pass")
    one_match_from_second_pass  = workbook.add_worksheet("one_match_from_second_pass")
    zero_matched_results        = workbook.add_worksheet("zero_matched_results")
    multiple_matched_results    = workbook.add_worksheet("multiple_matched_results")

    provider_header = header + [
      "address__uprn",
      "address__latitude",
      "address__longitude",
      ROW_TYPE_COL,
      FOUND_COL,
      MODEL_FIELDS_COL,
      OS_FIELDS_COL
    ]

    provider_header_index = provider_header.each_with_index.to_h

    provider_sheet.write_row(0, 0, provider_header)
    [one_match_from_first_pass,
     one_match_from_second_pass,
     zero_matched_results,
     multiple_matched_results].each do |sheet|
      sheet.write_row(0, 0, header + [ROW_TYPE_COL])
    end

    idx = {
      provider: 1,
      first_pass: 1,
      second_pass: 1,
      zero: 1,
      multiple: 1
    }

    # --------------------------
    # Helper lambdas
    # --------------------------
    apply_os_fields = lambda do |row, os_row|
      ADDRESS_FIELD_MAP.each { |os_key, col_name| row[provider_header_index[col_name]] = os_row[os_key] }
      OS_EXTRA_FIELD_MAP.each { |os_key, col_name| row[provider_header_index[col_name]] = os_row[os_key] }
    end

    set_provider_metadata = lambda do |row, row_type:, found:, model_field: nil, os_field: nil|
      row[provider_header_index[ROW_TYPE_COL]]     = row_type
      row[provider_header_index[FOUND_COL]]        = found
      row[provider_header_index[MODEL_FIELDS_COL]] = model_field
      row[provider_header_index[OS_FIELDS_COL]]    = os_field
    end

    # --------------------------
    # Process each row
    # --------------------------
    (2..sheet_in.last_row).each do |row_num|
      original_row = sheet_in.row(row_num)
      row_hash     = header.zip(original_row).to_h

      provider_row = Array.new(provider_header.size)
      header.each_with_index { |_, i| provider_row[i] = original_row[i] }

      matched = false
      postcode = row_hash["address__postcode"].to_s.strip

      os_results = OrdnanceSurvey::AddressLookupService.call(postcode: postcode, building_name_or_number: nil) || []

      # --------------------------
      # First pass: exactly 1 match
      # --------------------------
      if os_results.size == 1
        os = os_results.first
        apply_os_fields.call(provider_row, os)
        set_provider_metadata.call(provider_row, row_type: "updated", found: true)

        provider_sheet.write_row(idx[:provider], 0, provider_row)

        one_match_from_first_pass.write_row(idx[:first_pass], 0, original_row + ["original"])
        one_match_from_first_pass.write_row(idx[:first_pass] + 1, 0, provider_row[0, header.size] + ["chosen"])
        idx[:first_pass] += 2
        matched = true

      # --------------------------
      # Second pass: multiple matches
      # --------------------------
      elsif os_results.size > 1
        potentials = []

        MODEL_VS_OS_FIELD_COMBOS.each_with_index do |(model_field, os_field), rule_idx|
          val = row_hash[model_field].to_s.strip
          next if val.empty?

          matches = os_results.select { |r| r[os_field].to_s.strip.casecmp(val).zero? }
          potentials << { rule_index: rule_idx + 1,
                          model_field: model_field,
                          os_field: os_field,
                          os_row: matches.first } if matches.size == 1
        end

        if potentials.any?
          chosen = potentials.first
          apply_os_fields.call(provider_row, chosen[:os_row])
          set_provider_metadata.call(provider_row, row_type: "updated", found: true, model_field: chosen[:model_field],
                                                   os_field: chosen[:os_field])

          provider_sheet.write_row(idx[:provider], 0, provider_row)

          # second-pass audit sheet
          if idx[:second_pass] == 1
            one_match_from_second_pass.write_row(0, 0, header + [ROW_TYPE_COL, "second_pass_rule"])
            idx[:second_pass] += 1
          end

          write_idx = idx[:second_pass]
          one_match_from_second_pass.write_row(write_idx, 0, original_row + ["original", nil])
          write_idx += 1

          one_match_from_second_pass.write_row(write_idx, 0,
                                               provider_row[0, header.size] + ["chosen", chosen[:rule_index]])
          write_idx += 1

          potentials.drop(1).each do |pot|
            pot_row = Array.new(provider_header.size)
            header.each_with_index { |_, i| pot_row[i] = original_row[i] }
            apply_os_fields.call(pot_row, pot[:os_row])
            one_match_from_second_pass.write_row(write_idx, 0,
                                                 pot_row[0, header.size] + ["potential", pot[:rule_index]])
            write_idx += 1
          end

          idx[:second_pass] = write_idx
          matched = true
        end
      end

      # --------------------------
      # No match or unresolved
      # --------------------------
      unless matched
        set_provider_metadata.call(provider_row, row_type: "original", found: false)
        provider_sheet.write_row(idx[:provider], 0, provider_row)

        if os_results.empty?
          zero_matched_results.write_row(idx[:zero], 0, original_row + ["original"])
          idx[:zero] += 1
        else
          multiple_matched_results.write_row(idx[:multiple], 0, original_row + ["original"])
          idx[:multiple] += 1
        end
      end

      idx[:provider] += 1
    end

    workbook.close
    puts "Cleansed address washing machine complete: #{output_path}"
  end
end
