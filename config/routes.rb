# frozen_string_literal: true

Rails.application.routes.draw do
  # get 'auth/:provider/callback', to: 'sessions#create_from_google'
  # get 'auth/failure', to: redirect('/')
  # get 'signout', to: 'sessions#destroy', as: 'signout'

  # resources :sessions, only: %i[create destroy]
  resource :home, only: [:show]

  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks', registrations: 'registrations' }

  root to: 'home#show'
end
