class CreateWages < ActiveRecord::Migration
  def change
    create_table :wages do |t|
      t.references :project, null: false
      t.references :role, null: false
      t.integer :price, null: false
      t.date :start_date
      t.date :end_date
      t.integer :type, null: false
    end
    add_index :wages, [:project_id, :type]
    add_index :wages, :role_id
  end
end
