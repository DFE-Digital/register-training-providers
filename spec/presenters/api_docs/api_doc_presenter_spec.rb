require "rails_helper"

RSpec.describe ApiDocs::ApiDocPresenter do
  subject(:presenter) { described_class.new(spec:, method:) }

  let(:method) { :get }

  let(:spec) do
    {
      heading: "Providers",
      path: "/providers",
      specifications: {
        get: {
          summary: "Returns a list of providers",
          parameters: [
            {
              name: :updated_since,
              in: :query,
              required: false,
              schema: { type: :string },
              description: "Filter by update timestamp",
              example: "2025-09-14T11:34:56Z"
            }
          ],
          responses: {
            "200" => {
              description: "Successful response",
              content: {
                "application/json" => {
                  example: { data: [{ id: 1 }] }
                }
              }
            },
            "401" => {
              description: "Unauthorised",
              content: {
                "application/json" => {
                  example: { error: "Invalid token" }
                }
              }
            }
          }
        }
      }
    }
  end

  describe "#heading" do
    it "returns the heading" do
      expect(presenter.heading).to eq("Providers")
    end
  end

  describe "#summary" do
    it "returns the method summary" do
      expect(presenter.summary).to eq("Returns a list of providers")
    end
  end

  describe "#path" do
    it "returns the endpoint path" do
      expect(presenter.path).to eq("/providers")
    end
  end

  describe "#http_method" do
    it "returns the HTTP method in uppercase" do
      expect(presenter.http_method).to eq("GET")
    end
  end

  describe "#parameters" do
    it "returns the parameters array" do
      expect(presenter.parameters.size).to eq(1)
    end
  end

  describe "#parameter_rows" do
    it "maps parameters into table rows" do
      expect(presenter.parameter_rows).to eq([
        [
          "updated_since",
          "query",
          "string",
          "false",
          "Filter by update timestamp",
          "2025-09-14T11:34:56Z"
        ]
      ])
    end
  end

  describe "#responses" do
    it "returns the responses hash" do
      expect(presenter.responses.keys).to contain_exactly("200", "401")
    end
  end

  describe "#response" do
    it "returns a specific response by status code" do
      expect(presenter.response("200")[:description])
        .to eq("Successful response")
    end

    it "returns empty hash for unknown status" do
      expect(presenter.response("404")).to eq({})
    end
  end

  describe "#response_description" do
    it "returns the response description" do
      expect(presenter.response_description("401"))
        .to eq("Unauthorised")
    end
  end

  describe "#response_example" do
    it "returns the JSON example payload" do
      expect(presenter.response_example("200"))
        .to eq(data: [{ id: 1 }])
    end
  end

  describe "#pretty_response_example" do
    it "returns formatted JSON" do
      expect(presenter.pretty_response_example("200"))
        .to eq(JSON.pretty_generate(data: [{ id: 1 }]))
    end

    it "returns nil if no example exists" do
      expect(presenter.pretty_response_example("404")).to be_nil
    end
  end

  describe "when the HTTP method does not exist" do
    let(:method) { :post }

    it "raises KeyError" do
      expect { presenter.summary }.to raise_error(KeyError)
    end
  end
end
