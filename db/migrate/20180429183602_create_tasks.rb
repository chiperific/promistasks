# frozen_string_literal: true

class CreateTasks < ActiveRecord::Migration[5.1]
  def change
    create_table :tasks do |t|
      t.string :title, null: false      # google field
      t.string :notes                   # google field
      t.string :priority                # [urgent high medium low someday]
      t.datetime :due                   # google field
      t.references :creator,  references: :users, null: false
      t.references :owner,    references: :users, null: false
      t.references :subject,  references: :users, null: true, default: nil
      t.references :property,                     null: false
      t.monetize :budget, amount: { null: true, default: nil }
      t.monetize :cost,   amount: { null: true, default: nil }
      t.integer :visibility,       default: 0,     null: false # [[0, 'Staff'], [1, 'Everyone'], [2, 'Only associated people'], [3, 'Not clients']]
      t.boolean :license_required, default: false, null: false
      t.boolean :needs_more_info,  default: false, null: false
      t.string :status,                            null: false, default: 'needsAction' # google field: "needsAction" or "completed"
      t.datetime :discarded_at
      t.boolean :deleted,          default: false, null: false # google field
      t.boolean :hidden,           default: false, null: false # google field
      t.datetime :completed_at                        # google field -- completed
      t.datetime :google_updated                      # google field
      t.string :google_id                             # google field, Task ID
      t.string :position                              # google field
      t.integer :position_int, default: 0, limit: 8   # position field converted to an integer
      t.string :parent_id                             # google field
      t.string :previous_id
      t.boolean :initialization_template, null: false, default: false
      t.string :owner_type # ['Program Staff', 'Project Staff', 'Admin Staff']
      t.timestamps

      t.index :title
      t.index :google_id, unique: true
      t.index :position_int
      t.index :visibility
    end
  end
end
