module ApiRoutes
  def self.extended(router)
    router.instance_exec do
      namespace :api, path: "api/:api_version", api_version: /v[.0-9]/, defaults: { format: :json } do
        resource :info, controller: :info, only: :show, constraints: RouteConstraints::RegisterApiConstraint
        resources :providers, param: :slug, only: %i[index], constraints: RouteConstraints::RegisterApiConstraint

        # NOTE: catch all route
        match "*url" => "base#render_not_found", via: :all
      end
    end
  end
end
