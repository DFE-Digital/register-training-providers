Rails.application.routes.draw do
  extend ApiRoutes

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

  # System admin routes
  scope module: :system_admin, path: "system-admin" do
    mount Blazer::Engine, at: "/blazer", constraints: RouteConstraints::SystemAdminConstraint.new
    get "/blazer", to: redirect("/sign-in"), status: 302
  end

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

  get "/activity", to: "activity#index", as: :activity

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

  # Provider setup - addresses flow (reuses main address controllers)
  namespace :providers do
    namespace :setup, path: "new" do
      namespace :addresses do
        get "", to: "/providers/addresses/manual_entry#new", as: :address
        post "", to: "/providers/addresses/manual_entry#create"

        get "find", to: "/providers/addresses/find#new", as: :find
        post "find", to: "/providers/addresses/find#create"

        get "select", to: "/providers/addresses/select#new", as: :select
        post "select", to: "/providers/addresses/select#create"
      end
    end
  end

  resources :providers, except: [:new, :create] do
    checkable(:providers)
    resource :archive, only: [:show, :update], module: :providers
    resource :restore, only: [:show, :update], module: :providers
    resource :delete, only: [:show, :destroy], module: :providers
    get "activity", to: "providers/activity#index", as: :activity
    resources :accreditations, only: [:index], controller: "accreditations"
    resources :contacts, only: [:index, :new, :create, :edit, :update], controller: "providers/contacts" do
      checkable(:contacts, module_prefix: :providers)
      resource :delete, only: [:show, :destroy], module: "providers/contacts"
    end
    resources :partnerships, only: [:index], controller: "providers/partnerships"

    # === Addresses ===

    # Listing
    get "addresses", to: "providers/addresses/lists#index", as: :addresses

    # Manual entry (CRUD)
    get "addresses/new", to: "providers/addresses/manual_entry#new", as: :new_address
    post "addresses", to: "providers/addresses/manual_entry#create"
    get "addresses/:id/edit", to: "providers/addresses/manual_entry#edit", as: :edit_address
    patch "addresses/:id", to: "providers/addresses/manual_entry#update", as: :address

    # Finder flow
    get "addresses/find/new", to: "providers/addresses/find#new", as: :new_find
    post "addresses/find", to: "providers/addresses/find#create", as: :find
    get "addresses/select/new", to: "providers/addresses/select#new", as: :new_select
    post "addresses/select", to: "providers/addresses/select#create", as: :select

    # Check/confirm
    get "addresses/check/new", to: "providers/addresses/check#new", as: :new_address_confirm
    post "addresses/check", to: "providers/addresses/check#create", as: :address_confirm
    get "addresses/:id/check", to: "providers/addresses/check#show", as: :address_check
    patch "addresses/:id/check", to: "providers/addresses/check#update"

    # Delete
    get "addresses/:address_id/delete", to: "providers/addresses/deletes#show", as: :address_delete
    delete "addresses/:address_id/delete", to: "providers/addresses/deletes#destroy"

    # === Partnerships ===

    # Finder flow
    get "partnerships/find/new", to: "providers/partnerships/find#new", as: :new_partnership_find
    post "partnerships/find", to: "providers/partnerships/find#create", as: :partnership_find
    get "partnerships/dates/new", to: "providers/partnerships/dates#new", as: :new_partnership_dates
    post "partnerships/dates", to: "providers/partnerships/dates#create", as: :partnership_dates
    get "partnerships/academic_cycles/new", to: "providers/partnerships/academic_cycles#new",
                                            as: :new_partnership_academic_cycles
    post "partnerships/academic_cycles", to: "providers/partnerships/academic_cycles#create",
                                         as: :partnership_academic_cycles
    # Check/confirm
    get "partnerships/check/new", to: "providers/partnerships/check#new", as: :new_partnership_confirm
    post "partnerships/check", to: "providers/partnerships/check#create", as: :partnership_confirm

    # Edit partnership flow - entry point is dates#edit
    get "partnerships/:id/dates", to: "providers/partnerships/dates#edit", as: :edit_partnership_dates
    patch "partnerships/:id/dates", to: "providers/partnerships/dates#update"
    get "partnerships/:id/academic_cycles", to: "providers/partnerships/academic_cycles#edit",
                                            as: :edit_partnership_academic_cycles
    patch "partnerships/:id/academic_cycles", to: "providers/partnerships/academic_cycles#update"
    get "partnerships/:id/check", to: "providers/partnerships/check#show", as: :partnership_check
    patch "partnerships/:id/check", to: "providers/partnerships/check#update"
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
