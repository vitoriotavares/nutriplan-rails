Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Autenticação
  resource :session, only: [:new, :create, :destroy]
  resources :users, only: [:new, :create]
  get "signup", to: "users#new", as: :signup
  get "login", to: "sessions#new", as: :login
  delete "logout", to: "sessions#destroy", as: :logout
  
  # Anamnese e planos alimentares
  resources :anamneses do
    member do
      get :next_step
      get :previous_step
      post :generate_plan
    end
  end
  
  resources :food_plans do
    member do
      post :generate_pdf
      get :print
    end
    resources :meals, shallow: true do
      resources :food_items, shallow: true
    end
  end
  
  resources :recipes
  
  # Perfil do usuário
  resource :profile, only: [:show, :edit, :update]
  
  # Dashboard
  get "dashboard", to: "dashboard#index", as: :dashboard
  
  # Páginas estáticas
  get 'termos', to: 'static_pages#terms', as: :terms
  get 'privacidade', to: 'static_pages#privacy', as: :privacy
  get 'contato', to: 'static_pages#contact', as: :contact
  
  # Planos e assinaturas
  resources :plans, only: [:index, :show], path: 'planos' do
    collection do
      get :compare
    end
  end
  
  resources :subscriptions, only: [:index, :show, :new, :create], path: 'assinaturas' do
    member do
      patch :cancel
      get :payment_redirect
    end
    
    collection do
      get :success
      get :pending
      get :failure
    end
  end
  
  # Planos adicionais
  resources :additional_plans, only: [:new, :create], path: 'planos-adicionais' do
    collection do
      get :success
      get :pending
      get :failure
    end
  end
  
  # Webhooks
  post 'webhooks/mercado_pago', to: 'webhooks#mercado_pago', as: :mercado_pago_webhook
  
  # Defines the root path route ("/")
  root "home#index"
end
