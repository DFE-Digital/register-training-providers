# spec/lib/api_docs/openapi_specification_spec.rb
require "rails_helper"
require_relative "../../../app/lib/api_docs/openapi_specification"

RSpec.describe ApiDocs::OpenapiSpecification do
  describe ".specification" do
    it { expect(described_class.specification).to be_a(Hash) }
  end

  describe ".as_yaml" do
    it { expect(described_class.as_yaml).to be_a(String) }
  end

  describe ".as_hash" do
    it { expect(described_class.as_hash).to eq(described_class.specification) }
  end

  describe ".endpoints" do
    let(:endpoints) { described_class.endpoints }

    it "contains the expected keys" do
      expect(endpoints.keys).to contain_exactly("/info", "/providers")
    end

    it "builds a structured endpoint hash keyed by API path" do
      expect(endpoints.keys).to contain_exactly("/info", "/providers")
      expect(endpoints["/info"].keys).to contain_exactly("specifications", "heading", "path")
      expect(endpoints["/providers"].keys).to contain_exactly("specifications", "heading", "path")
    end

    it "stores the correct spec fragment under the verb key" do
      spec = described_class.specification

      expect(endpoints["/info"][:specifications][:get]).to eq(
        spec.dig("paths", "/api/{api_version}/info", "get")
      )
      expect(endpoints["/providers"][:specifications][:get]).to eq(
        spec.dig("paths", "/api/{api_version}/providers", "get")
      )
    end
  end

  context "manually added descriptions" do
    let(:openapi_data) { YAML.load_file(Rails.root.join("spec/support/openapi/post_documentation.yml")) }
    let(:spec) { described_class.specification }
    def find_param(path, method, param_name)
      spec.dig("paths", path, method, "parameters")&.find { |p| p["name"] == param_name }
    end

    def find_property(prop_name)
      spec.dig("paths", "/api/{api_version}/providers", "get", "responses", "200", "content", "application/json", "schema", "properties", "data", "items", "properties", prop_name)
    end

    context "parameters-level descriptions" do
      it "matches the data.yml for all parameters" do
        ["/api/{api_version}/info", "/api/{api_version}/providers"].each do |path|
          openapi_data["parameters"].each do |name, description|
            param = find_param(path, "get", name)
            next unless param #

            expect(param["description"].squish).to eq(description.squish)
          end
        end
      end
    end

    context "operation-level descriptions" do
      it "matches the data.yml for endpoint descriptions" do
        openapi_data["endpoints"].each do |path_key, data|
          # Find the path in the spec that includes our key
          full_path = spec["paths"].keys.find { |k| k.include?(path_key) }
          description = spec.dig("paths", full_path, "get", "description")

          expect(description.squish).to eq(data["description"].squish)
        end
      end
    end

    it "adds the data collection description" do
      data_property = spec.dig(
        "paths",
        "/api/{api_version}/providers",
        "get",
        "responses",
        "200",
        "content",
        "application/json",
        "schema",
        "properties",
        "data"
      )

      expect(data_property["description"]).to eq(
        openapi_data.dig(
          "providers_properties",
          "data",
          "description"
        )
      )
    end

    context "provider property descriptions" do
      it "matches the data.yml for all provider properties" do
        openapi_data["provider_properties"].each do |name, data|
          property = find_property(name)

          expect(property).to be_present, "Expected property '#{name}' to exist in schema"

          expect(property["description"].squish).to eq(data["description"].squish)

          expect(property["example"].to_s).to eq(data["example"].to_s) if data["example"]

          expect(property["enum"]).to eq(data["enum"]) if data["enum"]
        end
      end
    end
  end
end
