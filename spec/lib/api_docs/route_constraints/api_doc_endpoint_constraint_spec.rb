require "rails_helper"

RSpec.describe ApiDocs::RouteConstraints::ApiDocEndpointConstraint do
  let(:request) { instance_double("ActionDispatch::Request") }

  before do
    allow(request).to receive_message_chain(:path_parameters, :[]).with(:doc).and_return(doc)
    allow(request).to receive_message_chain(:path_parameters, :[]).with(:method).and_return(method)
  end

  describe ".matches?" do
    subject { described_class.matches?(request) }

    context "when the specification exists" do
      let(:doc)    { "info" }
      let(:method) { "get" }

      before do
        allow(ApiDocs::OpenapiSpecification).to receive(:has_specification?).with(doc, method).and_return(true)
      end

      it { is_expected.to be true }
    end

    context "when the specification does not exist" do
      let(:doc)    { "unknown" }
      let(:method) { "post" }

      before do
        allow(ApiDocs::OpenapiSpecification).to receive(:has_specification?).with(doc, method).and_return(false)
      end

      it { is_expected.to be false }
    end
  end
end
