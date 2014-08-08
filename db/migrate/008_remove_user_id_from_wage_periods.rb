class RemoveUserIdFromWagePeriods < ActiveRecord::Migration
  def up
    remove_index :wage_periods, :user_id
    remove_column :wage_periods, :user_id
  end

  def down
    add_column :wage_periods, :user_id, :integer, null: false
    add_index :wage_periods, :user_id
  end
end
