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

  # Provider creation wizard
  scope path: "/providers/new", as: :new_provider, module: :providers do
    get "", to: "onboarding#new", as: :onboarding
    post "", to: "onboarding#create"

    get "type", to: "type#new", as: :type
    post "type", to: "type#create"

    get "details", to: "details#new", as: :details
    post "details", to: "details#create"

    get "accreditation", to: "accreditation#new", as: :accreditation
    post "accreditation", to: "accreditation#create"
  end

  # Provider setup - addresses flow
  namespace :providers do
    namespace :setup, path: "new" do
      namespace :addresses do
        get "", to: "manual_entry#new", as: :address
        post "", to: "manual_entry#create"

        get "find", to: "find#new", as: :find
        post "find", to: "find#create"

        get "select", to: "select#new", as: :select
        post "select", to: "select#create"

        get "check", to: "check#new", as: :confirm
        post "check", to: "check#create"
      end
    end
  end

  resources :providers, except: [:new, :create] do
    checkable(:providers)
    resource :archive, only: [:show, :update], module: :providers
    resource :restore, only: [:show, :update], module: :providers
    resource :delete, only: [:show, :destroy], module: :providers
    resources :accreditations, only: [:index], controller: "accreditations"

    # Addresses - listing
    get "addresses", to: "providers/addresses/lists#index", as: :addresses

    # Addresses - manual entry
    get "addresses/new", to: "providers/addresses/manual_entry#new", as: :new_address
    post "addresses", to: "providers/addresses/manual_entry#create"
    get "addresses/:id/edit", to: "providers/addresses/manual_entry#edit", as: :edit_address
    patch "addresses/:id", to: "providers/addresses/manual_entry#update", as: :address
    put "addresses/:id", to: "providers/addresses/manual_entry#update"

    # Addresses - finder flow
    get "addresses/find/new", to: "providers/addresses/find#new", as: :new_find
    post "addresses/find", to: "providers/addresses/find#create", as: :find
    get "addresses/select/new", to: "providers/addresses/select#new", as: :new_select
    post "addresses/select", to: "providers/addresses/select#create", as: :select

    # Addresses - check/confirm
    get "addresses/check/new", to: "providers/addresses/check#new", as: :new_address_confirm
    post "addresses/check", to: "providers/addresses/check#create", as: :address_confirm
    get "addresses/:id/check", to: "providers/addresses/check#show", as: :address_check
    patch "addresses/:id/check", to: "providers/addresses/check#update"
    put "addresses/:id/check", to: "providers/addresses/check#update"

    # Addresses - delete
    get "addresses/:address_id/delete", to: "providers/addresses/deletes#show", as: :address_delete
    delete "addresses/:address_id/delete", to: "providers/addresses/deletes#destroy"
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
