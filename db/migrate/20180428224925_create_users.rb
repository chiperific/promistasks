# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string :provider
      t.string :uid
      t.string :name
      t.string :email
      t.string :encrypted_password
      t.string :google_image_link
      t.string :oauth_token
      t.datetime :oauth_expires_at
      t.timestamps
    end
  end
end
