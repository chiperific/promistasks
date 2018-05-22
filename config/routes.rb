# frozen_string_literal: true

Rails.application.routes.draw do
  resource :home, only: [:show]

  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks', registrations: 'registrations' }

  root to: 'tasks#public'
end
