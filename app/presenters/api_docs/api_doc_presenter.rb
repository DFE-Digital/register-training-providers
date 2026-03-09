module ApiDocs
  class ApiDocPresenter
    def initialize(spec:, method:)
      @spec = spec
      @method = method.to_sym
    end

    def heading
      @spec[:heading]
    end

    def summary
      method_spec[:summary]
    end

    def path
      @spec[:path]
    end

    def http_method
      @method.to_s.upcase
    end

    def parameters
      Array(method_spec[:parameters])
    end

    def parameter_rows
      parameters.map do |param|
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
      method_spec[:responses] || {}
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

    def method_spec
      @spec.fetch(:specifications).fetch(@method)
    end
  end
end
