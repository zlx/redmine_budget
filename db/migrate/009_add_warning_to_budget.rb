class AddWarningToBudget < ActiveRecord::Migration
  def change
    add_column :budgets, :warning_percent_threshold, :integer
    add_column :budgets, :warned_at, :timestamp
  end
end
