module ApiDocs
  class ApiDocPresenter
    def initialize(doc:, method:)
      @doc = doc
      @method = method.to_sym
    end

    def spec
      @spec ||= OpenapiSpecification.endpoints[doc_path]
    end

    def schema
      @schema ||= OpenapiSpecification.endpoint_table(doc_path, method)
    end

    def heading
      @heading ||= spec[:heading]
    end

    def summary
      @summary ||= method_spec[:summary]
    end

    def path
      @path ||= spec[:path]
    end

    def http_method
      @http_method ||= method.to_s.upcase
    end

    def parameters
      @parameters ||= Array(method_spec[:parameters])
    end

    def parameter_rows
      @parameter_rows ||= parameters.map do |param|
        [
          param[:name].to_s,
          param[:in].to_s,
          param.dig(:schema, :type).to_s,
          param[:required].to_s,
          param[:description].to_s,
          param[:example].to_s
        ]
      end
    end

    def responses
      @responses ||= method_spec[:responses] || {}
    end

    def response(status)
      responses[status.to_s] || {}
    end

    def response_description(status)
      response(status)[:description]
    end

    def response_example(status)
      response(status)
        .dig(:content, "application/json", :example)
    end

    def pretty_response_example(status)
      example = response_example(status)
      return unless example

      JSON.pretty_generate(example)
    end

  private

    attr_reader :doc, :method

    def method_spec
      @method_spec ||= spec.fetch(:specifications).fetch(@method)
    end

    def doc_path
      @doc_path ||= "/#{doc}"
    end
  end
end
