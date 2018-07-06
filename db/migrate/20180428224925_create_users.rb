# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :title
      t.boolean :program_staff, null: false, default: false
      t.boolean :project_staff, null: false, default: false
      t.boolean :admin_staff,   null: false, default: false
      t.boolean :client,        null: false, default: false
      t.boolean :volunteer,     null: false, default: false
      t.boolean :contractor,    null: false, default: false
      t.monetize :rate, default: 0
      t.string :phone1
      t.string :phone2
      t.string :address1
      t.string :address2
      t.string :city
      t.string :state, default: 'MI'
      t.string :postal_code

      ## Database authenticatable
      t.string :email,              null: false, default: ''
      t.string :encrypted_password, null: false, default: ''

      ## System-level
      t.boolean :system_admin, null: false, default: false

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, null: false, default: 0
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.inet     :current_sign_in_ip
      t.inet     :last_sign_in_ip

      ## Oauth / google_oauth2 fields
      t.string :oauth_provider
      t.string :oauth_id
      t.string :oauth_image_link
      t.string :oauth_token
      t.string :oauth_refresh_token
      t.datetime :oauth_expires_at

      t.timestamps
      t.datetime :discarded_at

      t.index :oauth_token, unique: true
      t.index :name,        unique: true
      t.index :email,       unique: true
    end
  end
end
