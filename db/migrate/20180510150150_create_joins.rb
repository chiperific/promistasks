# frozen_string_literal: true

class CreateJoins < ActiveRecord::Migration[5.1]
  def change
    create_table :connections do |t|
      t.references :property, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :relationship, null: false
      t.string :stage
      t.date :stage_date
      t.datetime :discarded_at
      t.timestamps
      t.index :stage
      t.index [:property_id, :user_id], unique: true
      t.index [:user_id, :property_id], unique: true
    end
  end

  create_table :skill_tasks do |t|
    t.references :skill, null: false, foreign_key: true
    t.references :task, null: false, foreign_key: true
    t.datetime :discarded_at
    t.index [:skill_id, :task_id], unique: true
    t.index [:task_id, :skill_id], unique: true
    t.index :discarded_at
  end

  create_table :skill_users do |t|
    t.references :skill, null: false, foreign_key: true
    t.references :user, null: false, foreign_key: true
    t.boolean :is_licensed, null: false, default: false
    t.datetime :discarded_at
    t.index [:skill_id, :user_id], unique: true
    t.index [:user_id, :skill_id], unique: true
    t.index :discarded_at
  end
end
