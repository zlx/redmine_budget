class AddNameToBudgetEntries < ActiveRecord::Migration
  def change
    add_column :budget_entries, :name, :string
  end
end
