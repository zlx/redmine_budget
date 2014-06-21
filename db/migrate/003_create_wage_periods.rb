class CreateWagePeriods < ActiveRecord::Migration
  def change
    create_table :wage_periods do |t|
      t.references :project, null: false
      t.references :user, null: false
      t.integer :cost_per_hour, null: false, default: 0
      t.integer :income_per_hour, null: false, default: 0
      t.date :start_date, null: false
      t.date :end_date, null: false
    end
    add_index :wage_periods, :project_id
    add_index :wage_periods, :user_id
  end
end
