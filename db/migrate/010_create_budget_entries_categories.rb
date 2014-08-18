class CreateBudgetEntriesCategories < ActiveRecord::Migration
  def change
    create_table :budget_entries_categories do |t|
      t.references :project
      t.string :name
      t.decimal :netto_amount
      t.decimal :tax
      t.integer :entry_type, :null => false
    end
    add_index :budget_entries_categories, :project_id
  end
end
