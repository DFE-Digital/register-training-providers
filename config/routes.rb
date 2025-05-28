Rails.application.routes.draw do
  root to: "landing_page#start"

  get :ping, controller: :heartbeat
  get :healthcheck, controller: :heartbeat
  get :sha, controller: :heartbeat

  scope via: :all do
    get "/404", to: "errors#not_found"
    get "/422", to: "errors#unprocessable_entity"
    get "/429", to: "errors#too_many_requests"
    get "/500", to: "errors#internal_server_error"
  end

  get "/sign-in" => "sign_in#index"
  get "/sign-out" => "sign_out#index"
  get "/sign-in/user-not-found", to: "sign_in#new"

  case Env.sign_in_method("dfe-sign-in")
  when "dfe-sign-in"
    get("/auth/dfe/callback" => "sessions#callback")
    get("/auth/dfe/sign-out" => "sessions#signout")
  when "otp"
    resource(:otp, only: %i[show create], controller: :otp, path: "request-sign-in-code")
    resource(:otp_verifications, only: %i[show create], path: "sign-in-code")
  when "persona"
    get("/personas", to: "personas#index")
    get("/auth/developer/sign-out", to: "sessions#signout")
    post("/auth/developer/callback", to: "sessions#callback")
  end

  resources :providers, only: %i[index]
end
