# spec/lib/api_docs/openapi_specification_spec.rb
require "rails_helper"
require_relative "../../../app/lib/api_docs/openapi_specification"

RSpec.describe ApiDocs::OpenapiSpecification do
  let(:yaml_path) { "public/openapi/v0.yaml" }
  let(:yaml_content) do
    <<~YAML
      paths:
        /api/{api_version}/info:
          get: {}
        /api/{api_version}/providers:
          get: {}
    YAML
  end

  before do
    allow(YAML).to receive(:load_file)
      .with(yaml_path, permitted_classes: [Time])
      .and_return(YAML.safe_load(yaml_content, permitted_classes: [Time]))
  end

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
end
