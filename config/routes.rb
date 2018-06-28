# frozen_string_literal: true

Rails.application.routes.draw do
  root to: 'tasks#public'

  resources :tasks do
    get 'discarded', on: :collection
  end

  resources :properties do
    get 'discarded', on: :collection
    get 'reports', on: :collection
  end

  resources :skills do
    get 'discarded', on: :collection
  end

  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks', registrations: 'registrations' }

  resources :users do
    get 'discarded', on: :collection
    get 'clear_completed_jobs', on: :collection
    get 'api_sync', on: :member
    get 'alerts', on: :member
  end

  mount DelayedJobProgress::Engine => '/delayed'
end
