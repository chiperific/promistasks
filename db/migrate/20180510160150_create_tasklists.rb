# frozen_string_literal: true

class CreateTasklists < ActiveRecord::Migration[6.0]
  def change
    create_table :tasklists do |t|
      t.string :google_id
      t.string :title, null: false
      t.boolean :auto_tasks_created, null: false, default: false
      t.references :user,     null: false, foreign_key: true
      t.timestamps

      t.index :google_id
      t.index :title
    end
  end
end
