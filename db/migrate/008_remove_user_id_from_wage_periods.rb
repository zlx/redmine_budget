class RemoveUserIdFromWagePeriods < ActiveRecord::Migration
  def change
    remove_index :wage_periods, :user_id
    remove_column :wage_periods, :user_id
  end
end
