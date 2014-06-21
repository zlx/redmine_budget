class CreateBudgets < ActiveRecord::Migration
  def change
    create_table :budgets do |t|
      t.references :project
      t.timestamp :updated_at
    end
    add_index :budgets, :project_id, unique: true
  end
end
