# frozen_string_literal: true

class CreateParks < ActiveRecord::Migration[5.2]
  def change
    create_table :parks do |t|
      t.string :name, null: false
      t.string :address
      t.string :city
      t.string :state, default: 'MI'
      t.string :postal_code
      t.text :notes
      t.string :poc_name
      t.string :poc_email
      t.string :poc_phone
      t.datetime :discarded_at
      t.float :latitude
      t.float :longitude
      t.datetime :discarded_at
      t.timestamps

      t.index :name, unique: true
      t.index :discarded_at
    end
  end
end
