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
      get :step1
      patch :save_step1
      get :step2
      patch :save_step2
      get :step3
      patch :save_step3
      get :step4
      patch :save_step4
      get :step5
      patch :save_step5
      get :summary
    end
  end
  
  resources :food_plans do
    resources :meals, shallow: true
    resource :water_plan
    get :grocery_list, on: :member
    get :download_pdf, on: :member
  end
  
  resources :recipes
  
  # Perfil do usuário
  resource :profile, only: [:show, :edit, :update]
  
  # Dashboard
  get "dashboard", to: "dashboard#index", as: :dashboard
  
  # Defines the root path route ("/")
  root "home#index"
end
