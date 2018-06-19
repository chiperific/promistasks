# frozen_string_literal: true

class CreateProperties < ActiveRecord::Migration[5.1]
  def change
    create_table :properties do |t|
      t.string :name,    null: false # google field: tasklist title
      t.string :address, null: false
      t.string :city
      t.string :state, default: 'MI'
      t.string :postal_code
      t.text :description
      t.date :acquired_on
      t.monetize :cost,     amount: { null: true, default: nil }
      t.monetize :lot_rent, amount: { null: true, default: nil }
      t.monetize :budget,   amount: { null: true, default: nil }
      t.string :certificate_number
      t.string :serial_number
      t.integer :year_manufacture
      t.string :manufacturer
      t.string :model
      t.string :certification_label1
      t.string :certification_label2
      t.references :creator, references: :users, null: false
      t.boolean :is_private,       default: false, null: false
      t.boolean :is_default,       default: false, null: false
      t.boolean :created_from_api, default: false, null: false
      t.datetime :discarded_at
      t.timestamps

      t.index :name,               unique: true
      t.index :address,            unique: true
      t.index :certificate_number, unique: true
      t.index :serial_number,      unique: true
      t.index :acquired_on
    end
  end
end
