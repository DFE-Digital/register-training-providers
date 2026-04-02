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
end
