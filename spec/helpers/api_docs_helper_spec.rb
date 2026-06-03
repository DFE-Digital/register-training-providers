require "rails_helper"

RSpec.describe ApiDocsHelper, type: :helper do
  describe "#api_docs_endpoint_path" do
    subject(:path) { helper.api_docs_endpoint_path(key, value) }

    let(:key)   { "/users" }
    let(:value) { "get" }

    before do
      allow(Rails.application.routes.url_helpers).to receive(:api_docs_page_path)
        .with(method: "get", doc: "users")
        .and_return("/api-docs/get/users")
    end

    it "strips the leading slash from the key" do
      path
      expect(Rails.application.routes.url_helpers)
        .to have_received(:api_docs_page_path)
        .with(hash_including(doc: "users"))
    end

    it "passes the correct HTTP method (derived from the hash key)" do
      path
      expect(Rails.application.routes.url_helpers)
        .to have_received(:api_docs_page_path)
        .with(hash_including(method: "get"))
    end

    it { is_expected.to eq "/api-docs/get/users" }

    context "when the key has no leading slash" do
      let(:key)   { "orders" }
      let(:value) { "post" }

      before do
        allow(Rails.application.routes.url_helpers).to receive(:api_docs_page_path)
          .with(method: "post", doc: "orders")
          .and_return("/api-docs/post/orders")
      end

      it { is_expected.to eq "/api-docs/post/orders" }

      it "uses the key unchanged" do
        path
        expect(Rails.application.routes.url_helpers)
          .to have_received(:api_docs_page_path)
          .with(hash_including(doc: "orders"))
      end
    end

    context "when the value hash does not contain a verb key" do
      let(:value) { nil }

      it "raises a KeyError" do
        expect { path }.to raise_error(KeyError)
      end
    end
  end

  describe "#schema_description" do
    subject(:result) { helper.schema_description(description, row_data) }

    let(:description) { "A provider type." }
    let(:row_data) { {} }

    it "returns the description text" do
      expect(result[:text].to_s).to include("A provider type.")
    end

    context "when enum values are present" do
      let(:row_data) do
        {
          enum: %w[hei school scitt]
        }
      end

      it "includes the possible values heading" do
        expect(result[:text].to_s).to include("Possible values:")
      end

      it "includes each enum value" do
        expect(result[:text].to_s).to include("hei")
        expect(result[:text].to_s).to include("school")
        expect(result[:text].to_s).to include("scitt")
      end
    end

    context "when a format is present" do
      let(:row_data) do
        {
          format: "date-time"
        }
      end

      it "includes the format description" do
        expect(result[:text].to_s)
          .to include("This field will be in the format date-time.")
      end
    end

    context "when the field is nullable" do
      let(:row_data) do
        {
          nullable: true
        }
      end

      it "includes the nullable description" do
        expect(result[:text].to_s)
          .to include("This field can also be null.")
      end
    end

    context "when enum, format and nullable are all present" do
      let(:row_data) do
        {
          enum: %w[accredited unaccredited],
          format: "date-time",
          nullable: true
        }
      end

      it "includes all supplementary information" do
        text = result[:text].to_s

        expect(text).to include("Possible values:")
        expect(text).to include("accredited")
        expect(text).to include("unaccredited")
        expect(text).to include("This field will be in the format date-time.")
        expect(text).to include("This field can also be null.")
      end
    end

    context "when enum is empty" do
      let(:row_data) do
        {
          enum: []
        }
      end

      it "does not include possible values" do
        expect(result[:text].to_s).not_to include("Possible values:")
      end
    end

    context "when nullable is false" do
      let(:row_data) do
        {
          nullable: false
        }
      end

      it "does not include the nullable message" do
        expect(result[:text].to_s)
          .not_to include("This field can also be null.")
      end
    end
  end
end
