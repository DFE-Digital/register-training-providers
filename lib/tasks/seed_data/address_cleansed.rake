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
FOUND_COL        = "address__found".freeze
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

    input_path =
      ENV["XLSX"] || Rails.root.join("lib/data/provider_seed_report_v_4.#{minor}_without_pii.xlsx").to_s

    output_path =
      Rails.root.join("lib/data/provider_seed_report_v_4.#{minor + 1}_without_pii.xlsx").to_s

    # --------------------------------------------------
    # Load input
    # --------------------------------------------------
    wb_in    = Roo::Spreadsheet.open(input_path)
    sheet_in = wb_in.sheet("providers")

    header = sheet_in.row(1).map(&:to_s)

    # --------------------------------------------------
    # Prepare output workbook
    # --------------------------------------------------
    workbook = WriteXLSX.new(output_path)

    provider_sheet            = workbook.add_worksheet("providers")
    first_pass_ws             = workbook.add_worksheet("one_match_from_first_pass")
    second_pass_ws            = workbook.add_worksheet("one_match_from_second_pass")
    zero_ws                   = workbook.add_worksheet("zero_matched_results")
    multiple_ws               = workbook.add_worksheet("multiple_matched_results")
    missing_addr1_ws          = workbook.add_worksheet("missing_line_1_results")

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

    [
      first_pass_ws,
      second_pass_ws,
      zero_ws,
      multiple_ws,
      missing_addr1_ws
    ].each do |ws|
      ws.write_row(0, 0, header + [ROW_TYPE_COL])
    end

    idx = Hash.new(1)

    # --------------------------------------------------
    # Helpers
    # --------------------------------------------------
    os_has_address_line_1 = lambda do |os_row|
      os_row["address_line_1"].to_s.strip.present?
    end

    apply_os_fields = lambda do |row, os_row|
      ADDRESS_FIELD_MAP.each do |os_key, col|
        row[provider_header_index[col]] = os_row[os_key]
      end
      OS_EXTRA_FIELD_MAP.each do |os_key, col|
        row[provider_header_index[col]] = os_row[os_key]
      end
    end

    set_metadata = lambda do |row, row_type:, found:, model_field: nil, os_field: nil|
      row[provider_header_index[ROW_TYPE_COL]]     = row_type
      row[provider_header_index[FOUND_COL]]        = found
      row[provider_header_index[MODEL_FIELDS_COL]] = model_field
      row[provider_header_index[OS_FIELDS_COL]]    = os_field
    end

    # --------------------------------------------------
    # Process rows
    # --------------------------------------------------
    (2..sheet_in.last_row).each do |row_num|
      original_row = sheet_in.row(row_num)
      row_hash     = header.zip(original_row).to_h

      provider_row = Array.new(provider_header.size)
      header.each_with_index { |_, i| provider_row[i] = original_row[i] }

      postcode = row_hash["address__postcode"].to_s.strip

      os_results = if postcode.blank?
                     []
                   else
                     OrdnanceSurvey::AddressLookupService.call(
                       postcode: postcode,
                       building_name_or_number: nil
                     ) || []

                   end

      valid_os_results = os_results.select { |r| os_has_address_line_1.call(r) }

      # --------------------------------------------------
      # OS responded but all results are invalid
      # --------------------------------------------------
      if os_results.any? && valid_os_results.empty?
        set_metadata.call(
          provider_row,
          row_type: "original",
          found: "address_line_1 has issues"
        )

        provider_sheet.write_row(idx[:provider], 0, provider_row)
        missing_addr1_ws.write_row(
          idx[:missing_address_line_1],
          0,
          original_row + ["original"]
        )

        idx[:missing_address_line_1] += 1
        idx[:provider] += 1
        next
      end

      matched = false

      # --------------------------------------------------
      # First pass – exactly one valid OS match
      # --------------------------------------------------
      if valid_os_results.size == 1
        os = valid_os_results.first

        apply_os_fields.call(provider_row, os)
        set_metadata.call(provider_row, row_type: "updated", found: true)

        provider_sheet.write_row(idx[:provider], 0, provider_row)

        first_pass_ws.write_row(idx[:first_pass],     0, original_row + ["original"])
        first_pass_ws.write_row(idx[:first_pass] + 1, 0, provider_row[0, header.size] + ["chosen"])

        idx[:first_pass] += 2
        matched = true

      # --------------------------------------------------
      # Second pass – rule-based disambiguation
      # --------------------------------------------------
      elsif valid_os_results.size > 1
        potentials = []

        MODEL_VS_OS_FIELD_COMBOS.each_with_index do |(model_field, os_field), rule_idx|
          model_val = row_hash[model_field].to_s.strip
          next if model_val.blank?

          matches = valid_os_results.select do |r|
            r[os_field].to_s.strip.casecmp(model_val).zero?
          end

          next unless matches.size == 1

          potentials << {
            rule_index: rule_idx + 1,
            model_field: model_field,
            os_field: os_field,
            os_row: matches.first
          }
        end

        if potentials.any?
          chosen = potentials.first

          apply_os_fields.call(provider_row, chosen[:os_row])
          set_metadata.call(
            provider_row,
            row_type: "updated",
            found: true,
            model_field: chosen[:model_field],
            os_field: chosen[:os_field]
          )

          provider_sheet.write_row(idx[:provider], 0, provider_row)

          if idx[:second_pass] == 1
            second_pass_ws.write_row(
              0,
              0,
              header + [ROW_TYPE_COL, "second_pass_rule"]
            )
            idx[:second_pass] += 1
          end

          write_idx = idx[:second_pass]

          second_pass_ws.write_row(write_idx, 0, original_row + ["original", nil])
          write_idx += 1

          second_pass_ws.write_row(
            write_idx,
            0,
            provider_row[0, header.size] + ["chosen", chosen[:rule_index]]
          )
          write_idx += 1

          potentials.drop(1).each do |pot|
            pot_row = Array.new(provider_header.size)
            header.each_with_index { |_, i| pot_row[i] = original_row[i] }

            apply_os_fields.call(pot_row, pot[:os_row])

            second_pass_ws.write_row(
              write_idx,
              0,
              pot_row[0, header.size] + ["potential", pot[:rule_index]]
            )
            write_idx += 1
          end

          idx[:second_pass] = write_idx
          matched = true
        end
      end

      # --------------------------------------------------
      # Zero or unresolved multiple matches
      # --------------------------------------------------
      unless matched
        set_metadata.call(provider_row, row_type: "original", found: false)
        provider_sheet.write_row(idx[:provider], 0, provider_row)

        if os_results.empty?
          zero_ws.write_row(idx[:zero], 0, original_row + ["original"])
          idx[:zero] += 1
        else
          multiple_ws.write_row(idx[:multiple], 0, original_row + ["original"])
          idx[:multiple] += 1
        end
      end

      idx[:provider] += 1
    end

    workbook.close
    puts "Cleansed address washing machine complete: #{output_path}"
  end
end
