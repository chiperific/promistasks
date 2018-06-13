# frozen_string_literal: true

class CreateTasks < ActiveRecord::Migration[5.1]
  def change
    create_table :tasks do |t|
      t.string :title, null: false                             # google field
      t.string :notes                                          # google field
      t.string :priority                                       # [urgent high medium low someday]
      t.datetime :due                                          # google field
      t.references :creator,  references: :users, null: false
      t.references :owner,    references: :users, null: false
      t.references :subject,  references: :users, null: true, default: nil
      t.references :property,                     null: false
      t.monetize :budget, amount: { null: true, default: nil }
      t.monetize :cost,   amount: { null: true, default: nil }
      t.integer :visibility,       default: 0,     null: false # [[0, 'Staff'], [1, 'Everyone'], [2, 'Only associated people'], [3, 'Not clients']]
      t.boolean :license_required, default: false, null: false
      t.boolean :needs_more_info,  default: false, null: false
      t.datetime :discarded_at
      t.datetime :completed_at                                 # google field -- completed, lives on this model because completing from one staff should complete for all
      t.boolean :initialization_template, default: false, null: false
      t.string :owner_type                                     # ['Program Staff', 'Project Staff', 'Admin Staff']
      t.timestamps

      t.index :title
      t.index [:title, :property_id], unique: true
      t.index [:property_id, :title], unique: true
    end
  end
end
