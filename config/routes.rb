# frozen_string_literal: true

Rails.application.routes.draw do
  root to: 'users#show'

  resources :users, only: %i[show destroy] do
    get 'tasklists', on: :member
  end

  resources :auto_tasks, only: %i[create update destroy]
  resources :tasklists, only: %i[create destroy]

  # devise_for :users, path: '', controllers: {
  #   omniauth_callbacks: 'omniauth_callbacks',
  #   registrations: 'registrations',
  #   sessions: 'sessions'
  # }

  get '/auth/:provider/callback', to: 'sessions#create'
  get '/in', to: 'sessions#new', as: :in
  get '/out' => 'sessions#destroy', as: :out
  get '/auth/failure', to: 'sessions#failure'
end
