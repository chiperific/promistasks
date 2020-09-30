# frozen_string_literal: true

Rails.application.routes.draw do
  root to: 'users#show'

  resources :users, only: %i[show destroy]

  resources :auto_tasks, except: %i[index show] do
    post 'reposition', on: :collection
  end

  resources :tasklists, only: %i[] do
    get 'push', on: :member
  end

  get '/auth/:provider/callback', to: 'sessions#create'
  get '/in', to: 'sessions#new', as: :in
  get '/out' => 'sessions#destroy', as: :out
  get '/auth/failure', to: 'sessions#failure'
end
