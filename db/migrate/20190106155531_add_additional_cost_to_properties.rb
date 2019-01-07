class AddAdditionalCostToProperties < ActiveRecord::Migration[5.2]
  def change
    change_table :properties do |t|
      t.monetize :additional_cost, amount: { null: true, default: nil }
    end
  end
end
