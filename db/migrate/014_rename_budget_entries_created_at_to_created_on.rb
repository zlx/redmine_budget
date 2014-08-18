class RenameBudgetEntriesCreatedAtToCreatedOn < ActiveRecord::Migration
  def up
    rename_column :budget_entries, :created_at, :created_on
    change_column :budget_entries, :created_on, :date
  end

  def down
    rename_column :budget_entries, :created_on, :created_at
    change_column :budget_entries, :created_at, :datetime
  end
end
