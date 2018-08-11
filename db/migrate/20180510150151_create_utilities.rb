# frozen_string_literal: true

class CreateUtilities < ActiveRecord::Migration[5.2]
  def change
    create_table :utilities do |t|
      t.string :name
      t.text :notes
      t.string :address
      t.string :city
      t.string :state, default: 'MI'
      t.string :postal_code
      t.string :poc_name
      t.string :poc_email
      t.string :poc_phone
      t.datetime :discarded_at
      t.float :latitude
      t.float :longitude
      t.timestamps

      t.index :name, unique: true
    end
  end
end
