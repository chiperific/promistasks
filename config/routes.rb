# frozen_string_literal: true

Rails.application.routes.draw do
  root to: 'tasks#public'

  get 'current_user_id', to: 'users#current_user_id'

  resources :tasks do
    get 'public', on: :collection
    get 'skills', on: :member
    post 'update_skills', on: :member
    get 'users_finder', on: :member
    get 'complete', on: :member
    get 'un_complete', on: :member
  end

  resources :properties do
    get 'list', on: :collection
    get 'reports', on: :collection
    get 'default', on: :collection
    get 'property_enum', on: :collection
    get 'find_id_by_name', on: :collection
    get 'tasks_filter', on: :member
  end

  resources :skills do
    get 'users', on: :member
    post 'update_users', on: :member
    get 'tasks', on: :member
    post 'update_tasks', on: :member
  end

  resources :connections

  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    registrations: 'registrations',
    sessions: 'sessions'
  }

  resources :users do
    get 'clear_completed_jobs', on: :collection
    get 'owner_enum', on: :collection
    get 'subject_enum', on: :collection
    get 'find_id_by_name', on: :collection
    get 'tasks', on: :member
    get 'tasks_finder', on: :member
    get 'skills', on: :member
    post 'update_skills', on: :member
    get 'api_sync', on: :member
    get 'alerts', on: :member
  end

  mount DelayedJobProgress::Engine => '/delayed'
end
