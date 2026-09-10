module LivingDocsRoutes
  def self.extended(router)
    router.instance_exec do
      scope path: "/living-docs", as: :living_docs do
        get "/", to: "living_docs/pages#home", as: :home
        get "/:path",
            to: "living_docs/pages#show",
            as: :page
      end
    end
  end
end
