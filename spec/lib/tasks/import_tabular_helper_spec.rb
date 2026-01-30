require "rails_helper"
require "roo"
require "csv"
require Rails.root.join("lib/tasks/import_tabular_helper")

RSpec.describe ImportTabularHelper do
  subject(:helper) { Class.new { extend ImportTabularHelper } }

  before do
    stub_const("DataImporter::ProviderService", provider_importer)
  end

  let(:provider_importer) do
    Class.new do
      def self.call(row)
        (@calls ||= []) << row
      end

      def self.calls
        @calls ||= []
      end

      def self.reset!
        @calls = []
      end
    end
  end

  after do
    provider_importer.reset!
  end

  describe "XLSX import" do
    let(:tmp_file) { Rails.root.join("tmp/test.xlsx").to_s }

    before do
      require "write_xlsx"

      workbook = WriteXLSX.new(tmp_file)
      sheet = workbook.add_worksheet("providers")

      sheet.write_row(0, 0, %w[header1 header2])
      sheet.write_row(1, 0, %w[a b])
      sheet.write_row(2, 0, %w[c d])
      sheet.write_row(3, 0, [nil, nil])

      workbook.close
    end

    after { FileUtils.rm_f(tmp_file) }

    it "imports all non-empty rows" do
      expect {
        helper.import_file(
          file_path: tmp_file,
          importer_class: DataImporter::ProviderService
        )
      }.to output(/2\/2 rows imported for providers/).to_stdout

      expect(provider_importer.calls.size).to eq(2)
      expect(provider_importer.calls.pluck("header1"))
        .to match_array(%w[a c])
    end

    it "continues when a row raises an error" do
      allow(provider_importer).to receive(:call) do |row|
        raise "Boom" if row["header1"] == "c"

        provider_importer.calls << row
      end

      expect {
        helper.import_file(
          file_path: tmp_file,
          importer_class: DataImporter::ProviderService
        )
      }.to output(/1\/2 rows imported for providers/).to_stdout

      expect(provider_importer.calls.size).to eq(1)
      expect(provider_importer.calls.first["header1"]).to eq("a")
    end

    it "aborts if the file does not exist" do
      expect {
        helper.import_file(
          file_path: "missing.xlsx",
          importer_class: DataImporter::ProviderService
        )
      }.to raise_error(Errno::ENOENT)
    end

    it "aborts if the sheet does not exist" do
      FileUtils.rm_f(tmp_file)

      require "write_xlsx"
      workbook = WriteXLSX.new(tmp_file)
      workbook.add_worksheet("wrong")
      workbook.close

      expect {
        helper.import_file(
          file_path: tmp_file,
          importer_class: DataImporter::ProviderService
        )
      }.to raise_error(ArgumentError)
    end
  end

  describe "CSV import" do
    let(:tmp_file) { Rails.root.join("tmp/test.csv").to_s }

    before do
      CSV.open(tmp_file, "w") do |csv|
        csv << %w[header1 header2]
        csv << %w[a b]
        csv << %w[c d]
      end
    end

    after { FileUtils.rm_f(tmp_file) }

    it "imports all rows" do
      expect {
        helper.import_file(
          file_path: tmp_file,
          importer_class: DataImporter::ProviderService
        )
      }.to output(/2\/2 rows imported for providers/).to_stdout

      expect(provider_importer.calls.size).to eq(2)
    end
  end
end
