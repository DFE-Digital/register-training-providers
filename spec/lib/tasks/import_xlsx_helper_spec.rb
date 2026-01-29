require "rails_helper"
require "roo"
require Rails.root.join("lib/tasks/import_xlsx_helper.rb")

RSpec.describe ImportXlsxHelper do
  let(:dummy_class) do
    Class.new do
      def self.call(row)
        (@calls ||= []) << row
      end

      def self.calls
        @calls ||= []
      end
    end
  end

  let(:tmp_file) { Rails.root.join("tmp/test.xlsx").to_s }

  before do
    require "write_xlsx"

    workbook = WriteXLSX.new(tmp_file)
    sheet = workbook.add_worksheet("Sheet1")
    sheet.write_row(0, 0, %w[header1 header2])
    sheet.write_row(1, 0, ["a", "b"])
    sheet.write_row(2, 0, ["c", "d"])
    sheet.write_row(3, 0, [nil, nil])
    workbook.close
  end

  after do
    FileUtils.rm_f(tmp_file)
  end

  describe "#import_xlsx" do
    it "calls importer_class for each non-empty row" do
      helper = Class.new { extend ImportXlsxHelper }

      expect {
        helper.import_xlsx(
          file_path: tmp_file,
          sheet_name: "Sheet1",
          importer_class: dummy_class
        )
      }.to output(/2\/2 rows imported/).to_stdout

      expect(dummy_class.calls.size).to eq(2)
      expect(dummy_class.calls.pluck("header1")).to match_array(%w[a c])
    end

    it "aborts if file does not exist" do
      helper = Class.new { extend ImportXlsxHelper }

      expect {
        helper.import_xlsx(
          file_path: "nonexistent.xlsx",
          sheet_name: "Sheet1",
          importer_class: dummy_class
        )
      }.to raise_error(Errno::ENOENT)
    end

    it "aborts if sheet does not exist" do
      helper = Class.new { extend ImportXlsxHelper }

      expect {
        helper.import_xlsx(
          file_path: tmp_file,
          sheet_name: "NoSheet",
          importer_class: dummy_class
        )
      }.to raise_error(ArgumentError)
    end

    it "rescues row exceptions and continues" do
      error_class = Class.new do
        def self.call(row)
          raise "Boom" if row["header1"] == "c"

          (@calls ||= []) << row
        end

        def self.calls
          @calls ||= []
        end
      end

      helper = Class.new { extend ImportXlsxHelper }

      expect {
        helper.import_xlsx(
          file_path: tmp_file,
          sheet_name: "Sheet1",
          importer_class: error_class
        )
      }.to output(/1\/2 rows imported/).to_stdout

      expect(error_class.calls.size).to eq(1)
      expect(error_class.calls.first["header1"]).to eq("a")
    end
  end
end
