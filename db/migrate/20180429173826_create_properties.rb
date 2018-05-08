class CreateProperties < ActiveRecord::Migration[5.1]
  def change
    create_table :properties do |t|
      t.string :name, null: false #tasklist title
      t.string :google_id
      t.string :selflink
      t.string :title_number
      t.string :address
      t.string :city
      t.string :state
      t.string :postal_code

      t.timestamps
      t.index :google_id, unique: true
    end
  end
end
