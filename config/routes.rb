Rails.application.routes.draw do
  def checkable(model, module_prefix: nil)
    if module_prefix
      # Handle nested modules like providers/addresses
      member do
        scope module: module_prefix do
          scope module: model do
            resource :check, only: %i[show update], path: "/check", controller: "check",
                             as: "#{model.to_s.singularize}_check"
          end
        end
      end

      collection do
        scope module: module_prefix do
          scope module: model do
            resource :check, only: %i[new create], path: "/check", as: "#{model.to_s.singularize}_confirm",
                             controller: "check"
          end
        end
      end
    else
      # Original behavior for simple cases
      resource :check, only: %i[show update], path: "/check", controller: "#{model}/check"

      collection do
        scope module: model do
          resource :check, only: %i[new create], path: "/check", as: "#{model.to_s.singularize}_confirm",
                           controller: "check"
        end
      end
    end
  end

  root to: "landing_page#start"

  get "/cookies", to: "pages#cookies"
  get "/accessibility", to: "pages#accessibility"
  get "/privacy", to: "pages#privacy"

  get :ping, controller: :heartbeat
  get :healthcheck, controller: :heartbeat
  get :sha, controller: :heartbeat

  scope via: :all do
    get "/404", to: "errors#not_found"
    get "/422", to: "errors#unprocessable_entity"
    get "/500", to: "errors#internal_server_error"
  end

  get "/sign-in" => "sign_in#index"
  get "/sign-out" => "sign_out#index"
  get "/sign-in/user-not-found", to: "sign_in#new"

  case Env.sign_in_method("dfe-sign-in")
  when "dfe-sign-in"
    get("/auth/dfe/callback" => "sessions#callback")
    get("/auth/dfe/sign-out" => "sessions#signout")
  when "persona"
    get("/personas", to: "personas#index")
    get("/auth/developer/sign-out", to: "sessions#signout")
    post("/auth/developer/callback", to: "sessions#callback")
  end

  resource :account, only: [:show]

  get "/providers/new", to: "providers/onboarding#new", as: :new_provider_onboarding
  post "/providers/new", to: "providers/onboarding#create"

  get "/providers/new/type", to: "providers/type#new", as: :new_provider_type
  post "/providers/new/type", to: "providers/type#create"

  get "/providers/new/details", to: "providers/details#new", as: :new_provider_details
  post "/providers/new/details", to: "providers/details#create"

  get "/providers/new/accreditation", to: "providers/accreditation#new", as: :new_provider_accreditation
  post "/providers/new/accreditation", to: "providers/accreditation#create"

  get "/providers/new/addresses", to: "providers/addresses#new", as: :new_provider_addresses
  post "/providers/new/addresses", to: "providers/addresses#create", as: :create_provider_addresses

  get "/providers/:provider_id/addresses/new", to: "providers/addresses#new", as: :new_provider_address
  post "/providers/:provider_id/addresses", to: "providers/addresses#create"

  resources :providers, except: [:new, :create] do
    checkable(:providers)
    resource :archive, only: [:show, :update], module: :providers
    resource :restore, only: [:show, :update], module: :providers
    resource :delete, only: [:show, :destroy], module: :providers
    resources :accreditations, only: [:index], controller: "accreditations"
    resources :addresses, only: [:index, :new, :create, :edit, :update], controller: "providers/addresses" do
      checkable(:addresses, module_prefix: :providers)
      resource :delete, only: [:show, :destroy], module: "providers/addresses"
    end
    resources :contacts, only: [:index], controller: "providers/contacts"
  end

  resources :accreditations, except: [:index, :show] do
    checkable(:accreditations)
    resource :delete, only: [:show, :destroy], module: :accreditations
  end

  resources :users do
    checkable(:users)
    resource :delete, only: [:show, :destroy], module: :users
  end
end
