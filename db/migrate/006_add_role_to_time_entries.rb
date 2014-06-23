class AddRoleToTimeEntries < ActiveRecord::Migration
  def change
    add_column :time_entries, :role_id, :integer, null: true
    add_index :time_entries, :role_id
    TimeEntry.reset_column_information
  end
end
