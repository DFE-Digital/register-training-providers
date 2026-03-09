module ApiDocs
  module RouteConstraints
    class ApiDocEndpointConstraint
      def self.matches?(request)
        doc    = request.path_parameters[:doc]
        method = request.path_parameters[:method]

        ApiDocs::OpenapiSpecification.has_specification?(doc, method)
      end
    end
  end
end
