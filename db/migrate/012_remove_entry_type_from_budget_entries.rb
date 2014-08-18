class RemoveEntryTypeFromBudgetEntries < ActiveRecord::Migration
  def up
    remove_column :budget_entries, :entry_type
  end

  def down
    add_column :budget_entries, :entry_type, :integer
  end
end
