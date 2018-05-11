# frozen_string_literal: true

class CreateProperties < ActiveRecord::Migration[5.1]
  def change
    create_table :properties do |t|
      t.string :name, null: false # tasklist title
      t.string :address
      t.string :city
      t.string :state
      t.string :postal_code
      t.text :description
      t.date :acquired_on
      t.monetize :cost, amount: { null: true, default: nil }
      t.monetize :lot_rent, amount: { null: true, default: nil }
      t.monetize :budget, amount: { null: true, default: nil }
      t.string :certificate_number
      t.string :serial_number
      t.integer :year_manufacture
      t.string :manufacturer
      t.string :model
      t.string :certification_label1
      t.string :certification_label2
      t.datetime :discarded_at
      t.string :google_id # tasklist ID
      t.string :selflink # tasklist full URL
      t.timestamps

      t.index :google_id, unique: true
      t.index :acquired_on
      t.index :certificate_number, unique: true
    end
  end
end
