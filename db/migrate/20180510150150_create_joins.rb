# frozen_string_literal: true

class CreateJoins < ActiveRecord::Migration[5.1]
  def change
    create_table :connections do |t|
      t.references :property, null: false, foreign_key: true
      t.references :user,     null: false, foreign_key: true
      t.string :relationship, null: false
      t.string :stage
      t.date :stage_date
      t.datetime :discarded_at
      t.timestamps
      t.index :stage
      t.index [:property_id, :user_id], unique: true
      t.index [:user_id, :property_id], unique: true
      t.index :discarded_at
    end

    create_table :skill_tasks do |t|
      t.references :skill, null: false, foreign_key: true
      t.references :task,  null: false, foreign_key: true
      t.datetime :discarded_at
      t.timestamps
      t.index [:skill_id, :task_id], unique: true
      t.index [:task_id, :skill_id], unique: true
      t.index :discarded_at
    end

    create_table :skill_users do |t|
      t.references :skill,    null: false, foreign_key: true
      t.references :user,     null: false, foreign_key: true
      t.boolean :is_licensed, null: false, default: false
      t.datetime :discarded_at
      t.timestamps
      t.index [:skill_id, :user_id], unique: true
      t.index [:user_id, :skill_id], unique: true
      t.index :discarded_at
    end

    create_table :tasklists do |t|
      t.references :user,     null: false, foreign_key: true
      t.references :property, null: false, foreign_key: true
      t.string :google_id
      t.timestamps
      t.index [:user_id, :property_id], unique: true
      t.index [:property_id, :user_id], unique: true
      t.index :google_id,               unique: true
    end

    create_table :task_users do |t|
      t.references :user, null: false, foreign_key: true
      t.references :task, null: false, foreign_key: true
      t.string :tasklist_gid                          # google field, but maintained from tasklist join table
      t.string :google_id                             # google field, Task ID
      t.string :position                              # google field
      t.integer :position_int, default: 0, limit: 8   # position field converted to an integer
      t.string :parent_id                             # google field
      t.string :previous_id
      t.boolean :deleted, default: false, null: false # google field
      t.datetime :completed_at                        # google field -- RFC 3339 timestamp
      t.timestamps
      t.index [:user_id, :task_id], unique: true
      t.index [:task_id, :user_id], unique: true
      t.index :google_id,           unique: true
      t.index :tasklist_gid
      t.index :position_int
    end
  end
end
