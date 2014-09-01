class AddWorkingHoursToBudgets < ActiveRecord::Migration
  def change
    add_column :budgets, :working_hours_start, :integer
    add_column :budgets, :working_hours_end, :integer
  end
end
