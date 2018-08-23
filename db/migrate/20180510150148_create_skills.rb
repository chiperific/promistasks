# frozen_string_literal: true

class CreateSkills < ActiveRecord::Migration[5.1]
  def change
    create_table :skills do |t|
      t.string :name, null: false
      t.boolean :license_required, default: false, null: false
      t.boolean :volunteerable, default: true, null: false
      t.datetime :discarded_at
      t.timestamps
      t.index :name, unique: true
      t.index :discarded_at
    end
  end
end
