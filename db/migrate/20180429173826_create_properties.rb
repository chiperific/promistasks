# frozen_string_literal: true

class CreateProperties < ActiveRecord::Migration[5.1]
  def change
    create_table :properties do |t|
      t.string :name, null: false # google field: tasklist title
      t.string :address
      t.string :city
      t.string :state, default: 'MI'
      t.string :postal_code
      t.text :description
      t.date :acquired_on
      t.references :park, null: true
      t.monetize :cost,     amount: { null: true, default: nil }
      t.monetize :lot_rent, amount: { null: true, default: nil }
      t.monetize :budget,   amount: { null: true, default: nil }
      t.string :stage,      null: false, default: 'acquired'
      t.date :expected_completion_date
      t.date :actual_completion_date
      t.string :certificate_number
      t.string :serial_number
      t.integer :year_manufacture
      t.string :manufacturer
      t.integer :beds,  null: false, default: 1
      t.integer :baths, null: false, default: 1
      t.references :creator, references: :users, null: false
      t.boolean :is_private,       default: false, null: false
      t.boolean :is_default,       default: false, null: false
      t.boolean :ignore_budget_warning, default: false, null: false
      t.boolean :created_from_api, default: false, null: false
      t.datetime :discarded_at
      t.float :latitude
      t.float :longitude
      t.timestamps

      t.index :name,    unique: true
      t.index :address, unique: true
      t.index :acquired_on
      t.index :discarded_at
    end
  end
end
