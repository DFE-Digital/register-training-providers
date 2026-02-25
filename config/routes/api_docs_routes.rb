module ApiDocsRoutes
  def self.extended(router)
    router.instance_exec do
      scope path: "/api-docs", as: :api_docs do
        get "/", to: "api_docs/pages#home", as: :home
      end
    end
  end
end
