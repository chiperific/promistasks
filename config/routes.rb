# frozen_string_literal: true

Rails.application.routes.draw do
  root to: 'users#show'


  resources :tasklists do
    resources :tasks
  end

  devise_for :users, path: '', controllers: {
    omniauth_callbacks: 'omniauth_callbacks',
    registrations: 'registrations',
    sessions: 'sessions'
  }

  resources :users
end
