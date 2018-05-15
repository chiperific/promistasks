class CreateExcludePropertyUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :exclude_property_users do |t|
      t.references :user, null: false, foreign_key: true
      t.references :property, null: false, foreign_key: true
      t.timestamps
      t.index [:user_id, :property_id], unique: true
      t.index [:property_id, :user_id], unique: true
    end
  end
end
