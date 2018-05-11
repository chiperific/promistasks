# frozen_string_literal: true

class CreateTasks < ActiveRecord::Migration[5.1]
  def change
    create_table :tasks do |t|
      t.string :title, null: false      # google field
      t.string :notes                   # google field
      t.string :priority                # [urgent high medium low someday]
      t.string :status                  # google field: "needsAction" or "completed"
      t.string :google_id               # google field
      t.datetime :due                   # google field
      t.datetime :completed             # google field
      t.datetime :discarded_at
      t.boolean :deleted                # google field
      t.boolean :hidden                 # google field
      t.string :position, null: false   # google field
      t.string :parent_id               # google field
      t.string :previous_id
      t.references :creator, references: :users, null: false
      t.references :owner, references: :users, null: false
      t.references :subject, references: :users, null: true, default: nil
      t.references :property, null: true, default: nil
      t.boolean :license_required,  default: false, null: false
      t.monetize :budget, amount: { null: true, default: nil }
      t.monetize :cost,   amount: { null: true, default: nil }
      t.boolean :visible_only_to_staff, default: true, null: false
      t.boolean :initialization_template
      t.string :owner_type # ['Program Staff', 'Project Staff', 'Admin Staff']

      t.timestamps
      t.index :google_id, unique: true
    end
  end
end
