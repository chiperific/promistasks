# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string :provider
      t.string :uid
      t.string :name, null: false
      t.string :title
      t.boolean :system_admin,  null: false, default: false
      t.boolean :program_staff, null: false, default: false
      t.boolean :project_staff, null: false, default: false
      t.boolean :admin_staff,   null: false, default: false
      t.boolean :client,        null: false, default: false
      t.boolean :volunteer,     null: false, default: false
      t.boolean :contractor,    null: false, default: false
      t.string :phone1
      t.string :phone2
      t.string :address1
      t.string :address2
      t.string :city
      t.string :state, default: 'MI'
      t.string :postal_code
      t.monetize :rate, default: 0

      ## Database authenticatable
      t.string :email,              null: false, default: ''
      t.string :encrypted_password, null: false, default: ''

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, null: false, default: 0
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.inet     :current_sign_in_ip
      t.inet     :last_sign_in_ip

      t.string :google_image_link
      t.string :oauth_token
      t.datetime :oauth_expires_at
      t.datetime :discarded_at
      t.timestamps
    end

    add_index :users, :oauth_token,          unique: true
    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
  end
end
