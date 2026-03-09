module ApiDocsRoutes
  def self.extended(router)
    router.instance_exec do
      scope path: "/api-docs", as: :api_docs do
        get "/", to: "api_docs/pages#home", as: :home
        get "/:method/:doc",
            to: "api_docs/pages#show",
            as: :page,
            constraints: ApiDocs::RouteConstraints::ApiDocEndpointConstraint
      end
    end
  end
end
