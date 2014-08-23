class RemoveDefaultValuesFromBudgetEntriesCategories < ActiveRecord::Migration
  def up
    remove_column :budget_entries_categories, :netto_amount
    remove_column :budget_entries_categories, :tax
  end


  def down
    add_column :budget_entries_categories, :netto_amount, :decimal
    add_column :budget_entries_categories, :tax, :decimal
  end
end
