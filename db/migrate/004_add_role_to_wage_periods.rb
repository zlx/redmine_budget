class AddRoleToWagePeriods < ActiveRecord::Migration
  def change
    add_column :wage_periods, :role_id, :integer, null: false
    add_index :wage_periods, :role_id
  end
end
