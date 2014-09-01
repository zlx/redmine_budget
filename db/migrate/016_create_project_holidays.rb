class CreateProjectHolidays < ActiveRecord::Migration
  def change
    create_table :project_holidays do |t|
      t.references :project
      t.date :date
    end
    add_index :project_holidays, :project_id
  end
end
