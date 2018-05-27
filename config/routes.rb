# frozen_string_literal: true

Rails.application.routes.draw do
  root to: 'tasks#public'

  resources :tasks
  resources :properties, path: 'lists'
  # mount RailsAdmin::Engine => '/admin', as: 'rails_admin'

  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks', registrations: 'registrations' }

end
