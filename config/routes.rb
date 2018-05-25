# frozen_string_literal: true

Rails.application.routes.draw do
  # resources :tasks

  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'

  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks', registrations: 'registrations' }

  root to: 'tasks#public'
end
