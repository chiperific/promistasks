# frozen_string_literal: true

class CreateTasks < ActiveRecord::Migration[5.1]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.string :notes
      t.string :status
      t.string :google_id
      t.datetime :due
      t.datetime :completed
      t.boolean :deleted
      t.boolean :hidden
      t.string :parent_id
      t.string :previous_id

      t.timestamps
      t.index :google_id, unique: true
    end
  end
end
