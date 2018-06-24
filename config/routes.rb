# frozen_string_literal: true

Rails.application.routes.draw do
  root to: 'tasks#public'

  resources :tasks do
    get 'discarded', on: :collection
  end

  resources :properties, path: 'lists' do
    get 'discarded', on: :collection
  end

  resources :users do
    get 'discarded', on: :collection
    get 'api_sync', on: :member
  end
  # mount RailsAdmin::Engine => '/admin', as: 'rails_admin'

  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks', registrations: 'registrations' }

  mount DelayedJobProgress::Engine => '/delayed'
end
