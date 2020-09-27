# frozen_string_literal: true

class CreateAutoTasks < ActiveRecord::Migration[6.0]
  def change
    create_table :auto_tasks do |t|
      t.string :title, null: false
      t.string :notes
      t.integer :position, null: false, default: 0
      t.integer :days_until_due, null: false, default: 0
      t.references :user, null: false, foreign_key: true
      t.timestamps

      t.index :title
      t.index :position, unique: true
    end
  end
end
