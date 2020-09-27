# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      ## Oauth / google_oauth2 fields
      t.string :oauth_provider
      t.string :oauth_id
      t.string :oauth_image_link
      t.string :oauth_token
      t.string :oauth_refresh_token
      t.datetime :oauth_expires_at

      t.timestamps

      t.index :oauth_token, unique: true
      t.index :oauth_id,    unique: true
      t.index :name,        unique: true
      t.index :email,       unique: true
    end
  end
end
