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
    context "parameters-level descriptions" do
      it "ensures all parameters across all endpoints have descriptions" do
        spec = described_class.specification
        spec["paths"].each do |path, path_item|
          path_item.each do |method, operation|
            next unless operation.is_a?(Hash)
            next unless operation["parameters"]

            operation["parameters"].each do |param|
              expect(param["description"]).to be_present,
                                              "Missing description for #{method.upcase} #{path} parameter #{param['name']}"
            end
          end
        end
      end

      shared_examples "parameters-level descriptions" do |hash_keys, descriptions|
        it "has description for #{hash_keys.join(' -> ')}" do
          expect(described_class.specification.dig(*hash_keys).pluck("description").map(&:squish)).to eq(descriptions)
        end
      end

      context "manually added parameters-level descriptions" do
        it_behaves_like "parameters-level descriptions", ["paths", "/api/{api_version}/info", "get", "parameters"], [
          "A valid API token must be provided in the Authorization header to access this endpoint.",
          "The API version to use in the request path. This should be set to the latest version for this endpoint."
        ]

        it_behaves_like "parameters-level descriptions", ["paths", "/api/{api_version}/providers", "get", "parameters"], [
          "A valid API token must be provided in the Authorization header to access this endpoint.",
          "Filters providers by the specified academic year. The value must be a 4-digit year, for example 2025. If not provided, the API will return providers active in the current academic year.",
          "The API version to use in the request path. This should be set to the latest version for this endpoint.",
          "Filters providers to only those updated after the specified timestamp. The value must be an ISO 8601 datetime, for example: 2025-09-14T11:34:56Z.",
        ]
      end
    end

    context "operation-level descriptions" do
      it "ensures all operations across all endpoints have descriptions" do
        spec = described_class.specification
        spec["paths"].each do |path, path_item|
          path_item.each do |method, operation|
            next unless operation.is_a?(Hash)
            # Skip keys that aren't HTTP verbs
            next unless %w[get post put patch delete options head].include?(method.downcase)

            expect(operation["description"]).to be_present,
                                                "Missing description for #{method.upcase} #{path} operation"
          end
        end
      end

      shared_examples "operation-level description" do |hash_keys, descriptions|
        it "has description for #{hash_keys.join(' -> ')}" do
          expect(described_class.specification.dig(*hash_keys).squish).to eq(descriptions)
        end
      end
      context "manually added operation-level descriptions" do
        it_behaves_like "operation-level description", ["paths", "/api/{api_version}/info", "get", "description"], "This endpoint can be used to retrieve general information about the API."
        it_behaves_like "operation-level description", ["paths", "/api/{api_version}/providers", "get", "description"],
                        "This endpoint can be used to retrieve providers for a given academic year. This is intended to make it possible to check for new or updated providers regularly."
      end
    end
  end
end
