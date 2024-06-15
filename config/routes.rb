Rails.application.routes.draw do
  root 'games#index'

  post 'sessions/create'
  delete 'sessions/destroy'

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  resources :games, only: [:index, :show]
  resources :moves, only: [:create]

  get 'pieces/:id/select', to: 'pieces#set_as_selected'
  get 'pieces/deselect', to: 'pieces#deselect'
end
