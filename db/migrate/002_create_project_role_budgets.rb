class CreateProjectRoleBudgets < ActiveRecord::Migration
  def change
    create_table :project_role_budgets do |t|
      t.references :project, null: false
      t.references :role, null: false
      t.integer :hours_count, null: false
    end
    add_index :project_role_budgets, :project_id
    add_index :project_role_budgets, :role_id
    add_index :project_role_budgets, [:project_id, :role_id], unique: true
  end
end
