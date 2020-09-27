# frozen_string_literal: true

Rails.application.routes.draw do
  root to: '/canvas'

  get '/canvas', to: 'users#show'

  resources :users, only: [:show, :destroy] do
    get 'in', on: :collection
    get 'oauth', on: :collection
    get 'out', on: :member
  end

  resources :auto_tasks, only: [:create, :update, :destroy]
  resources :tasklists, only: [:create, :destroy]

  # devise_for :users, path: '', controllers: {
  #   omniauth_callbacks: 'omniauth_callbacks',
  #   registrations: 'registrations',
  #   sessions: 'sessions'
  # }

  get '/auth/:provider/callback', to: 'users#oauth'
end
