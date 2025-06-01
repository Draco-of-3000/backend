Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes
  namespace :api do
    namespace :v1 do
      # User management
      resources :users, only: [:create, :show]
      
      # Game room management
      resources :game_rooms, only: [:index, :create, :show], param: :code do
        member do
          post :join
          post :start_game
          get :state
          post :play_card
          post :draw_card
        end
      end
    end
  end

  # Action Cable mount point
  mount ActionCable.server => '/cable'

  # Defines the root path route ("/")
  # root "posts#index"
end
