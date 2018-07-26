class RemoveIndexesFromConnecitons < ActiveRecord::Migration[5.2]
  def change
    remove_index :connections, column: [:property_id, :user_id]
    remove_index :connections, column: [:user_id, :property_id]
    remove_index :connections, column: :stage
  end
end
