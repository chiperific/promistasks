class AddScopeToTaskUser < ActiveRecord::Migration[5.2]
  def change
    add_column :task_users, :scope, :string
  end
end
