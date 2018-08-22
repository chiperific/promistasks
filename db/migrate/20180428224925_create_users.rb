# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string   :name, null: false
      t.string   :title
      t.string   :phone,      null: false
      t.boolean  :admin,      null: false, default: false
      t.boolean  :staff,      null: false, default: false
      t.boolean  :client,     null: false, default: false
      t.boolean  :volunteer,  null: false, default: false
      t.boolean  :contractor, null: false, default: false
      t.monetize :rate,       null: false, default: 0 # contractors only
      t.integer  :adults,     null: false, default: 1 # clients only
      t.integer  :children,   null: false, default: 0 # clients only

      ## Database authenticatable
      t.string :email,              null: false, default: ''
      t.string :encrypted_password, null: false, default: ''

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
      t.index :oauth_id,    unique: true
      t.index :name,        unique: true
      t.index :email,       unique: true
      t.index :discarded_at
    end
  end
end
