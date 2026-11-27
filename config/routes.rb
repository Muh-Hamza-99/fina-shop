Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # fina.shop: marketing and signup
  constraints Hosts::Apex do
    root "home#index"
  end

  # app.fina.shop: merchant admin
  constraints Hosts::Admin do
    scope module: :admin, as: :admin do
      root "dashboards#show"

      resources :products, only: :index
      resources :categories, only: :index
      resources :quote_requests, only: :index
      resources :customers, only: :index
      resource :analytics, only: :show
      resource :theme, only: :show
      resource :store_settings, only: :show
      resource :billing, only: :show

      get "signup", to: "signups#new"
      post "signup", to: "signups#create"
      resource :session, only: %i[new create destroy]
      resources :passwords, param: :token, only: %i[new create edit update]
    end
  end

  # <slug>.fina.shop or a custom domain: buyer storefront
  constraints Hosts::Storefront do
    scope module: :storefront, as: :storefront do
      root "homes#show"
    end
  end
end
