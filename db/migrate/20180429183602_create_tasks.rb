# frozen_string_literal: true

class CreateTasks < ActiveRecord::Migration[5.1]
  def change
    create_table :tasks do |t|
      t.string :title, null: false                             # google field
      t.string :notes                                          # google field
      t.integer :priority                                      # [['urgent', 0], ['high', 1], ['medium', 2], ['low', 3], ['someday', 4]]
      t.datetime :due                                          # google field
      t.references :creator,  references: :users, null: false
      t.references :owner,    references: :users, null: false
      t.references :subject,  references: :users, null: true, default: nil
      t.references :property,                     null: false
      t.monetize :budget, amount: { null: true, default: nil }
      t.monetize :cost,   amount: { null: true, default: nil }
      t.integer :visibility,       default: 0,     null: false # [['Staff', 0], ['Everyone', 1], ['Only associated people', 2], ['Not clients', 3]]
      t.boolean :needs_more_info,  default: false, null: false
      t.datetime :discarded_at
      t.datetime :completed_at                                 # google field -- completed, lives on this model because completing from one staff should complete for all
      t.string :owner_type                                     # ['Program Staff', 'Project Staff', 'Admin Staff']
      t.boolean :created_from_api, default: false, null: false
      t.timestamps

      t.index :title
      t.index [:title, :property_id], unique: true
      t.index [:property_id, :title], unique: true
    end
  end
end
