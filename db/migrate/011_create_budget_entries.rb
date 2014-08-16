class CreateBudgetEntries < ActiveRecord::Migration
  def change
    create_table :budget_entries do |t|
      t.references :project
      t.decimal :netto_amount
      t.decimal :tax
      t.integer :entry_type
      t.references :category
      t.references :issue
      t.datetime :created_at
      t.references :user
      t.decimal :deposit_amount
      t.boolean :planned
    end
    add_index :budget_entries, :project_id
    add_index :budget_entries, :category_id
    add_index :budget_entries, :issue_id
    add_index :budget_entries, :user_id
  end
end
